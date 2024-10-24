#!/usr/bin/env bash

set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

eval "$(ssh-agent)"
ssh-add /etc/gitshell/kp

mkdir -p /root/.ssh
ssh-keyscan github.com >>/root/.ssh/known_hosts

function g()
(
  mkdir -p ./tmp
  
  while mountpoint -q ./tmp
  do
    umount ./tmp
    sleep 1
  done
  
  mount -t tmpfs none ./tmp
  
  cd ./tmp
  
  git clone git@github.com:lorenzosaintdubois/inductor.git
  
  cd ./inductor
  
  bash ./entrypoint.sh
)

last_known_sha="unknown"

function f()
{
  curl -L \
       -H "Accept: application/vnd.github+json" \
       -H "Authorization: Bearer ""$(cat /etc/gitshell/token)" \
       -H "X-GitHub-Api-Version: 2022-11-28" \
       https://api.github.com/repos/lorenzosaintdubois/inductor/branches \
       >./body
  
  cat ./body
  
  current_sha="$(cat ./body | jq ".[0].commit.sha")"
  
  if [ "$current_sha" != "$last_known_sha" ]
  then
    g
  fi
  
  last_known_sha="$current_sha"
}

while [ 1 ]
do
  f
  sleep 90
done
