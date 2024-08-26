#!/usr/bin/env fish

set g_version "1.0.0"
set g_build "2024-04-18"
set g_author "AJ ONeal <aj@therootcompany.com> (https://bnna.net)"
set g_license "CC0-1.0"
set g_license_url "https://creativecommons.org/publicdomain/zero/1.0/"
if test "$argv[1]" = "version" -o "$argv[1]" = "--version" -o "$argv[1]" = "-V"
    echo "ssh-agent.sh v$g_version ($g_build)"
    echo "copyright 2024 $g_author ($g_license license)"
    echo "$g_license_url"
    exit 0
end
if test "$argv[1]" = "help" -o "$argv[1]" = "--help"
    echo "ssh-agent.sh v$g_version ($g_build)"
    echo "copyright 2024 $g_author ($g_license license)"
    echo "$g_license_url"
    echo ""
    echo 'ssh-agent.sh uses `source`ry to load a working instance of the local SSH agent in a POSIX-compatible shell - to be able to git push with the local (not forwarded) credentials, for example.'
    echo ""
    echo "USAGE"
    echo "    . ssh-agent.sh"
    echo ""
    exit 0
end
set -e g_version g_build g_author g_license g_license_url


set g_caller (status current-command)
if test "source" != "$g_caller";
    echo ''
    echo 'USAGE'
    echo "    source $g_caller"
    echo ''
    exit 1
end
set -e g_caller


# Ex:
#     SSH_AUTH_SOCK=/var/folders/fh/xxxxxxxx/T//ssh-xxxxx/agent.23456; export SSH_AUTH_SOCK;
#     SSH_AGENT_PID=12345; export SSH_AGENT_PID;
#     echo Agent pid 12345;
set g_out (ssh-agent -s)

# Ex:
#     SSH_AUTH_SOCK=/var/folders/fh/xxxxxxxx/T//ssh-xxxxx/agent.23456
#     SSH_AGENT_PID=12345
#     12345
set g_set_ssh_auth_sock (echo "$g_out[1]" | cut -d';' -f1)
set g_set_ssh_agent_pid (echo "$g_out[2]" | cut -d';' -f1)
set g_ssh_agent_pid (echo "$g_out[3]" | cut -d';' -f1 | cut -d' ' -f4)

set -e g_out

eval "export $g_set_ssh_auth_sock"
eval "export $g_set_ssh_agent_pid"
echo "Agent pid $g_ssh_agent_pid"

set -e g_set_ssh_auth_sock
set -e g_set_ssh_agent_pid
set -e g_ssh_agent_pid

ssh-add
