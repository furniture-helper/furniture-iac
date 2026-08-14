#!/bin/bash
set -e

TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION="${AVAILABILITY_ZONE::-1}"
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
  --filters "Name=tag:Name,Values=${PROJECT}-kafka-eip" \
  --query "Addresses[0].AllocationId" \
  --output text)

if [ -z "$EIP_ALLOCATION_ID" ] || [ "$EIP_ALLOCATION_ID" = "None" ]; then
  echo "Error: static Elastic IP allocation not found for ${PROJECT}-kafka-eip"
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
dnf install -y java-17-amazon-corretto-devel wget tar awscli

cd /opt
curl -L -o kafka_2.13-4.3.1.tgz https://downloads.apache.org/kafka/4.3.1/kafka_2.13-4.3.1.tgz
tar -xzf kafka_2.13-4.3.1.tgz
mv kafka_2.13-4.3.1 kafka
cd kafka

# Find the config file (KRaft mode uses different paths in 4.3.1)
CONFIG_FILE=$(find . -name "server.properties" -type f | head -1)

if [ -z "$CONFIG_FILE" ]; then
  echo "Error: server.properties not found"
  exit 1
fi

# Configure dual listeners:
# - INTERNAL for local access over SSM (localhost)
# - EXTERNAL for remote access from outside the instance
sed -i "s|^listeners=.*|listeners=INTERNAL://:19092,EXTERNAL://:9092,CONTROLLER://:9093|g" "$CONFIG_FILE"
sed -i "s|^advertised.listeners=.*|advertised.listeners=INTERNAL://localhost:19092,EXTERNAL://$PUBLIC_IP:9092|g" "$CONFIG_FILE"
sed -i "s|^listener.security.protocol.map=.*|listener.security.protocol.map=CONTROLLER:PLAINTEXT,INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT|g" "$CONFIG_FILE"
sed -i "s|^inter.broker.listener.name=.*|inter.broker.listener.name=INTERNAL|g" "$CONFIG_FILE"

# Attach and mount persistent EBS volume
VOLUME_ID=$(aws ec2 describe-volumes \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=${PROJECT}-kafka-data" "Name=availability-zone,Values=$AVAILABILITY_ZONE" \
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

  for i in $(seq 1 60); do
    ATTACHED_INSTANCE_ID=$(aws ec2 describe-volumes \
      --region "$REGION" \
      --volume-ids "$VOLUME_ID" \
      --query "Volumes[0].Attachments[0].InstanceId" \
      --output text)

    if [ "$ATTACHED_INSTANCE_ID" = "None" ]; then
      break
    fi

    if [ "$ATTACHED_INSTANCE_ID" = "$INSTANCE_ID" ]; then
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
for i in $(seq 1 30); do
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

# Update Kafka to use mounted volume
sed -i "s|log.dirs=.*|log.dirs=/mnt/kafka-data/logs|" "$CONFIG_FILE"

KAFKA_CLUSTER_ID=$(bin/kafka-storage.sh random-uuid)
if [ ! -f /mnt/kafka-data/logs/meta.properties ]; then
  bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c "$CONFIG_FILE" --standalone
fi
bin/kafka-server-start.sh -daemon "$CONFIG_FILE"

# Wait for broker startup, then ensure crawler events topic exists
until bin/kafka-topics.sh --bootstrap-server localhost:19092 --list >/dev/null 2>&1; do
  sleep 2
done
bin/kafka-topics.sh --bootstrap-server localhost:19092 \
  --create --if-not-exists \
  --topic "crawler-events" \
  --partitions 1 \
  --replication-factor 1