package terraform.tags

# 1. Tags you want to enforce
required_tags := {"Name", "Project"}

# 2. Resources that DO NOT support tags (The Exception List)
# You must maintain this. If a build fails on a valid resource, add it here.
ignored_resources := {
    "aws_eip_association",
    "aws_route_table_association",
    "aws_main_route_table_association",
    "aws_security_group_rule",
    "aws_iam_role_policy_attachment",
    "aws_iam_user_policy_attachment",
    "aws_lb_listener",
    "aws_lb_target_group_attachment",
    "aws_autoscaling_attachment",
    "random_string",
    "random_password",
    "tls_private_key",
    "aws_iam_role_policy"
}

deny contains msg if {
    # Loop through all resources in the plan
    resource := input.resource_changes[_]

    # Check 1: Must be a managed resource
    resource.mode == "managed"

    # Check 2: Must NOT be in our ignored list
    not ignored_resources[resource.type]

    # Check 3: Ignore resources being deleted
    not is_being_deleted(resource)

    # Logic: Get the tags (default to empty object if missing)
    tags := object.get(resource.change.after, "tags", {})

    # Check: Loop through required tags
    req_tag := required_tags[_]

    # Fail if the tag is missing
    not tags[req_tag]

    msg := sprintf(
        "Resource '%v' (Type: %v) is missing required tag: '%v'. (If this resource does not support tags, add it to 'ignored_resources' in tags.rego)",
        [resource.address, resource.type, req_tag]
    )
}

is_being_deleted(r) if {
    r.change.actions[_] == "delete"
    count(r.change.actions) == 1
}