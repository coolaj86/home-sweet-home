#!/bin/sh
set -e
set -u

g_version="1.0.0"
g_build="2024-04-18"
g_author="AJ ONeal <aj@therootcompany.com> (https://bnna.net)"
g_license="CC0-1.0"
g_license_url="https://creativecommons.org/publicdomain/zero/1.0/"
if test "version" = "${1:-}" || test "--version" = "${1:-}" || test "-V" = "${1:-}"; then
    echo "ssh-agent.sh v${g_version} (${g_build})"
    echo "copyright 2024 ${g_author} (${g_license} license)"
    echo "${g_license_url}"
    exit 0
fi
if test "help" = "${1:-}" || test "--help" = "${1:-}"; then
    {
        echo "ssh-agent.sh v${g_version} (${g_build})"
        echo "copyright 2024 ${g_author} (${g_license} license)"
        echo "${g_license_url}"
        echo ""
        # shellcheck disable=SC2016 # use of literal $ is intentional
        echo 'ssh-agent.sh uses `source`ry to load a working instance of the local SSH agent in a POSIX-compatible shell - to be able to git push with the local (not forwarded) credentials, for example.'
        echo ""
        echo "USAGE"
        echo "    . ssh-agent.sh"
        echo ""
    } >&2
    exit 0
fi
unset g_version
unset g_build
unset g_author
unset g_license
unset g_license_url

#
# Ensure the script was `source`d, not not called directly
#
g_caller="$(basename "${0}")"
if test "ssh-agent.sh" = "$g_caller"; then
    {
        echo ''
        echo 'USAGE'
        echo "    . ${0}"
        echo ''
    } >&2
    exit 1
fi
unset g_caller

#
# Everything is global so the variables will be sourced into the callers environment
#

# Ex:
#     SSH_AUTH_SOCK=/var/folders/fh/xxxxxxxx/T//ssh-xxxxx/agent.23456; export SSH_AUTH_SOCK;
#     SSH_AGENT_PID=12345; export SSH_AGENT_PID;
#     echo Agent pid 12345;
g_out="$(ssh-agent -s)"

# Ex:
#     SSH_AUTH_SOCK=/var/folders/fh/xxxxxxxx/T//ssh-xxxxx/agent.23456
#     SSH_AGENT_PID=12345
#     12345
g_set_ssh_auth_sock="$(echo "${g_out}" | grep -m 1 "export SSH_AUTH_SOCK;" | cut -d';' -f1)"
g_set_ssh_agent_pid="$(echo "${g_out}" | grep -m 1 "export SSH_AGENT_PID;" | cut -d';' -f1)"
g_ssh_agent_pid="$(echo "${g_out}" | grep -m 1 "echo" | cut -d';' -f1 | cut -d' ' -f4)"

unset g_out

eval "export ${g_set_ssh_auth_sock}"
unset g_set_ssh_auth_sock

eval "export ${g_set_ssh_agent_pid}"
unset g_set_ssh_agent_pid

echo "Agent pid ${g_ssh_agent_pid}"
unset g_ssh_agent_pid

ssh-add
