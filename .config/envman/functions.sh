#!/bin/sh
# no strict mode because this is 'source'd

_aws_set_profile() {
    export AWS_PROFILE="${1:-default}"
    echo "$AWS_PROFILE"
}
