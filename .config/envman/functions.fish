#!/usr/bin/env fish
# no strict mode because this is 'source'd

function _aws_set_profile
    set -gx AWS_PROFILE (or $argv[1] "default")
    echo "$AWS_PROFILE"
end
