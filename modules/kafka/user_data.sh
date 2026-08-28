#!/bin/bash
set -e

TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION="$${AVAILABILITY_ZONE::-1}"
PROJECT=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/tags/instance/Project)

if ! command -v aws >/dev/null 2>&1; then
  echo "Error: awscli is required before network bootstrap"
  exit 1
fi

if [ -z "$PROJECT" ]; then
  echo "Error: unable to resolve Project instance tag for Kafka resource discovery"
  exit 1
fi

EIP_ALLOCATION_ID=$(aws ec2 describe-addresses \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=$${PROJECT}-kafka-eip" \
  --query "Addresses[0].AllocationId" \
  --output text)

if [ -z "$EIP_ALLOCATION_ID" ] || [ "$EIP_ALLOCATION_ID" = "None" ]; then
  echo "Error: static Elastic IP allocation not found for $${PROJECT}-kafka-eip"
  exit 1
fi

aws ec2 associate-address \
  --region "$REGION" \
  --instance-id "$INSTANCE_ID" \
  --allocation-id "$EIP_ALLOCATION_ID" \
  --allow-reassociation

PUBLIC_IP=$(aws ec2 describe-addresses \
  --region "$REGION" \
  --allocation-ids "$EIP_ALLOCATION_ID" \
  --query "Addresses[0].PublicIp" \
  --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "None" ]; then
  echo "Error: unable to resolve Elastic IP public address for Kafka external listener"
  exit 1
fi

dnf update -y
dnf install -y docker awscli jq nginx

if ! dnf install -y certbot python3-certbot-dns-route53; then
  dnf install -y python3-pip
  pip3 install certbot certbot-dns-route53
fi

# Attach and mount persistent EBS volume
VOLUME_ID=$(aws ec2 describe-volumes \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=$${PROJECT}-kafka-data" "Name=availability-zone,Values=$AVAILABILITY_ZONE" \
  --query "Volumes[0].VolumeId" \
  --output text)

if [ -z "$VOLUME_ID" ] || [ "$VOLUME_ID" = "None" ]; then
  echo "Error: persistent Kafka EBS volume not found in $AVAILABILITY_ZONE"
  exit 1
fi

ATTACHED_INSTANCE_ID=$(aws ec2 describe-volumes \
  --region "$REGION" \
  --volume-ids "$VOLUME_ID" \
  --query "Volumes[0].Attachments[0].InstanceId" \
  --output text)

if [ "$ATTACHED_INSTANCE_ID" = "None" ]; then
  aws ec2 attach-volume --region "$REGION" --volume-id "$VOLUME_ID" --instance-id "$INSTANCE_ID" --device /dev/sdf
  aws ec2 wait volume-in-use --region "$REGION" --volume-ids "$VOLUME_ID"
elif [ "$ATTACHED_INSTANCE_ID" != "$INSTANCE_ID" ]; then
  echo "Kafka EBS volume $VOLUME_ID is attached to $ATTACHED_INSTANCE_ID. Waiting for safe takeover..."

  for _ in $(seq 1 60); do
    ATTACHED_INSTANCE_ID=$(aws ec2 describe-volumes \
      --region "$REGION" \
      --volume-ids "$VOLUME_ID" \
      --query "Volumes[0].Attachments[0].InstanceId" \
      --output text)

    if [ "$ATTACHED_INSTANCE_ID" = "None" ] || [ "$ATTACHED_INSTANCE_ID" = "$INSTANCE_ID" ]; then
      break
    fi

    ATTACHED_INSTANCE_STATE=$(aws ec2 describe-instances \
      --region "$REGION" \
      --instance-ids "$ATTACHED_INSTANCE_ID" \
      --query "Reservations[0].Instances[0].State.Name" \
      --output text 2>/dev/null || true)

    if [ -z "$ATTACHED_INSTANCE_STATE" ] || [ "$ATTACHED_INSTANCE_STATE" = "None" ] || [ "$ATTACHED_INSTANCE_STATE" = "shutting-down" ] || [ "$ATTACHED_INSTANCE_STATE" = "stopping" ] || [ "$ATTACHED_INSTANCE_STATE" = "stopped" ] || [ "$ATTACHED_INSTANCE_STATE" = "terminated" ]; then
      aws ec2 detach-volume --region "$REGION" --volume-id "$VOLUME_ID" --force
      aws ec2 wait volume-available --region "$REGION" --volume-ids "$VOLUME_ID"
      break
    fi

    sleep 5
  done

  ATTACHED_INSTANCE_ID=$(aws ec2 describe-volumes \
    --region "$REGION" \
    --volume-ids "$VOLUME_ID" \
    --query "Volumes[0].Attachments[0].InstanceId" \
    --output text)

  if [ "$ATTACHED_INSTANCE_ID" != "None" ] && [ "$ATTACHED_INSTANCE_ID" != "$INSTANCE_ID" ]; then
    echo "Error: Kafka EBS volume $VOLUME_ID is still attached to active instance $ATTACHED_INSTANCE_ID"
    exit 1
  fi

  aws ec2 attach-volume --region "$REGION" --volume-id "$VOLUME_ID" --instance-id "$INSTANCE_ID" --device /dev/sdf
  aws ec2 wait volume-in-use --region "$REGION" --volume-ids "$VOLUME_ID"
fi

DATA_DEVICE=""
for _ in $(seq 1 30); do
  for candidate in /dev/nvme1n1 /dev/xvdf /dev/sdf; do
    if [ -b "$candidate" ]; then
      DATA_DEVICE="$candidate"
      break
    fi
  done
  if [ -n "$DATA_DEVICE" ]; then
    break
  fi
  sleep 2
done

if [ -z "$DATA_DEVICE" ]; then
  echo "Error: Kafka data device not found after EBS attachment"
  exit 1
fi

if ! blkid "$DATA_DEVICE" >/dev/null 2>&1; then
  mkfs.ext4 "$DATA_DEVICE"
fi

mkdir -p /mnt/kafka-data
if ! mountpoint -q /mnt/kafka-data; then
  mount "$DATA_DEVICE" /mnt/kafka-data
fi

DATA_DEVICE_UUID=$(blkid -s UUID -o value "$DATA_DEVICE")
if ! grep -q "UUID=$DATA_DEVICE_UUID /mnt/kafka-data" /etc/fstab; then
  echo "UUID=$DATA_DEVICE_UUID /mnt/kafka-data ext4 defaults,nofail 0 2" >> /etc/fstab
fi

mkdir -p /mnt/kafka-data/kafbat-ui-data
chmod 777 /mnt/kafka-data/kafbat-ui-data

dnf install -y java-17-amazon-corretto-devel wget tar

KAFKA_VERSION="4.3.1"
KAFKA_HOME="/opt/kafka-broker"
KAFKA_DATA_DIR="/mnt/kafka-data"
KAFKA_LOG_DIR="$KAFKA_DATA_DIR/kafka-logs"
KAFKA_CONFIG="$KAFKA_HOME/config/server.properties"

mkdir -p "$KAFKA_LOG_DIR" "$KAFKA_HOME"

if [ ! -f "$KAFKA_HOME/bin/kafka-server-start.sh" ]; then
  rm -rf "$KAFKA_HOME"
  cd /opt
  curl -fL "https://downloads.apache.org/kafka/$KAFKA_VERSION/kafka_2.13-$KAFKA_VERSION.tgz" -o kafka_2.13-$KAFKA_VERSION.tgz
  tar -xzf "kafka_2.13-$KAFKA_VERSION.tgz"
  mv "kafka_2.13-$KAFKA_VERSION" "$KAFKA_HOME"
fi

if [ ! -f "$KAFKA_CONFIG" ]; then
  echo "Error: Kafka server.properties not found at $KAFKA_CONFIG"
  exit 1
fi

set_kafka_config() {
  local key="$1"
  local value="$2"

  if grep -q "^$key=" "$KAFKA_CONFIG"; then
    sed -i "s|^$key=.*|$key=$value|" "$KAFKA_CONFIG"
  else
    echo "$key=$value" >> "$KAFKA_CONFIG"
  fi
}

sed -i '/^controller\.quorum\.voters=/d' "$KAFKA_CONFIG"

set_kafka_config "process.roles" "broker,controller"
set_kafka_config "node.id" "1"
set_kafka_config "controller.quorum.bootstrap.servers" "localhost:9093"
set_kafka_config "listeners" "INTERNAL://:19092,EXTERNAL://:9092,CONTROLLER://:9093"
set_kafka_config "advertised.listeners" "INTERNAL://localhost:19092,EXTERNAL://$PUBLIC_IP:9092"
set_kafka_config "listener.security.protocol.map" "CONTROLLER:PLAINTEXT,INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT"
set_kafka_config "inter.broker.listener.name" "INTERNAL"
set_kafka_config "controller.listener.names" "CONTROLLER"
set_kafka_config "log.dirs" "$KAFKA_LOG_DIR"
set_kafka_config "num.partitions" "1"
set_kafka_config "offsets.topic.replication.factor" "1"
set_kafka_config "transaction.state.log.replication.factor" "1"
set_kafka_config "transaction.state.log.min.isr" "1"
set_kafka_config "group.initial.rebalance.delay.ms" "0"

if [ ! -f "$KAFKA_LOG_DIR/meta.properties" ] && [ ! -f "$KAFKA_HOME/logs/meta.properties" ]; then
  KAFKA_CLUSTER_ID=$("$KAFKA_HOME/bin/kafka-storage.sh" random-uuid)
  "$KAFKA_HOME/bin/kafka-storage.sh" format \
    -t "$KAFKA_CLUSTER_ID" \
    -c "$KAFKA_CONFIG" \
    --standalone
fi

cat > /etc/systemd/system/kafka.service <<EOF
[Unit]
Description=Kafka Broker
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$KAFKA_HOME
ExecStart=$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_CONFIG
ExecStop=$KAFKA_HOME/bin/kafka-server-stop.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now kafka

for _ in $(seq 1 60); do
  if "$KAFKA_HOME/bin/kafka-topics.sh" --bootstrap-server localhost:19092 --list >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

"$KAFKA_HOME/bin/kafka-topics.sh" --bootstrap-server localhost:19092 --create --if-not-exists --topic crawler-events --partitions 1 --replication-factor 1 || true

systemctl enable docker
systemctl start docker
systemctl enable nginx

COMPOSE_CMD="docker compose"
if ! docker compose version >/dev/null 2>&1; then
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64) COMPOSE_ARCH="x86_64" ;;
    aarch64) COMPOSE_ARCH="aarch64" ;;
    *)
      echo "Error: unsupported architecture for Docker Compose: $ARCH"
      exit 1
      ;;
  esac

  COMPOSE_VERSION="v2.29.7"
  mkdir -p /usr/libexec/docker/cli-plugins
  curl -fL "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-linux-$COMPOSE_ARCH" \
    -o /usr/libexec/docker/cli-plugins/docker-compose
  chmod +x /usr/libexec/docker/cli-plugins/docker-compose

  if ! docker compose version >/dev/null 2>&1; then
    echo "Error: Docker Compose plugin bootstrap failed"
    exit 1
  fi
fi

DB_SECRET_JSON=$(aws secretsmanager get-secret-value \
  --region "$REGION" \
  --secret-id "${database_credentials_secret_arn}" \
  --query "SecretString" \
  --output text)

if [ -z "$DB_SECRET_JSON" ] || [ "$DB_SECRET_JSON" = "None" ]; then
  echo "Error: unable to fetch database credentials secret"
  exit 1
fi

MB_DB_USER=$(echo "$DB_SECRET_JSON" | jq -r '.username // empty')
MB_DB_PASS=$(echo "$DB_SECRET_JSON" | jq -r '.password // empty')
MB_DB_DBNAME=$(echo "$DB_SECRET_JSON" | jq -r '.database_name // empty')

if [ -z "$MB_DB_USER" ] || [ -z "$MB_DB_PASS" ] || [ -z "$MB_DB_DBNAME" ]; then
  echo "Error: database credentials secret is missing username/password/database_name"
  exit 1
fi

LETSENCRYPT_DATA_DIR="/mnt/kafka-data/letsencrypt"
mkdir -p "$LETSENCRYPT_DATA_DIR"

if [ ! -L /etc/letsencrypt ]; then
  if [ -d /etc/letsencrypt ] && find /etc/letsencrypt -mindepth 1 -print -quit | grep -q .; then
    cp -a /etc/letsencrypt/. "$LETSENCRYPT_DATA_DIR"/
  fi
  rm -rf /etc/letsencrypt
  ln -s "$LETSENCRYPT_DATA_DIR" /etc/letsencrypt
fi

request_certificate() {
  local cert_name="$1"
  local domain="$2"
  local cert_dir="/etc/letsencrypt/live/$cert_name"

  if [ -f "$cert_dir/fullchain.pem" ]; then
    return
  fi

  certbot certonly \
    --non-interactive \
    --agree-tos \
    --register-unsafely-without-email \
    --dns-route53 \
    --cert-name "$cert_name" \
    --keep-until-expiring \
    --dns-route53-propagation-seconds 30 \
    -d "$domain"
}

KAFKA_CERT_NAME="kafka-proxy"
KAFKA_CERT_DIR="/etc/letsencrypt/live/$KAFKA_CERT_NAME"
METABASE_CERT_NAME="metabase-proxy"
METABASE_CERT_DIR="/etc/letsencrypt/live/$METABASE_CERT_NAME"

request_certificate "$KAFKA_CERT_NAME" "kafka.furniture.kaneel.xyz"
request_certificate "$METABASE_CERT_NAME" "metabase.furniture.kaneel.xyz"

mkdir -p /opt/kafka
cat > /opt/kafka/docker-compose.yml <<'EOF'
${docker_compose_content}
EOF

cat > /opt/kafka/.env <<EOF
MB_DB_TYPE=postgres
MB_DB_DBNAME=$MB_DB_DBNAME
MB_DB_PORT=5432
MB_DB_USER=$MB_DB_USER
MB_DB_PASS=$MB_DB_PASS
MB_DB_HOST=${rds_db_endpoint}
EOF

cat > /etc/nginx/conf.d/kafka-metabase.conf <<'EOF'
server {
  listen 80;
  server_name kafka.furniture.kaneel.xyz;
  return 301 https://$host$request_uri;
}

server {
  listen 80;
  server_name metabase.furniture.kaneel.xyz;
  return 301 https://$host$request_uri;
}

server {
  listen 443 ssl;
  http2 on;
  server_name kafka.furniture.kaneel.xyz;

  ssl_certificate __KAFKA_CERT_DIR__/fullchain.pem;
  ssl_certificate_key __KAFKA_CERT_DIR__/privkey.pem;

  location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}

server {
  listen 443 ssl;
  http2 on;
  server_name metabase.furniture.kaneel.xyz;

  ssl_certificate __METABASE_CERT_DIR__/fullchain.pem;
  ssl_certificate_key __METABASE_CERT_DIR__/privkey.pem;

  location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
EOF

sed -i "s|__KAFKA_CERT_DIR__|$KAFKA_CERT_DIR|g" /etc/nginx/conf.d/kafka-metabase.conf
sed -i "s|__METABASE_CERT_DIR__|$METABASE_CERT_DIR|g" /etc/nginx/conf.d/kafka-metabase.conf

cd /opt/kafka
$COMPOSE_CMD --env-file /opt/kafka/.env pull
$COMPOSE_CMD --env-file /opt/kafka/.env up -d
nginx -t
systemctl restart nginx