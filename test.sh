#!/usr/bin/bash

function checkjenkins {
  S=`curl -f --silent http://localhost:6060/api/json | grep -Po 'mode'`
  if [[ $S ]]; then
    return 0
  else
    echo "waiting for jekins..."
    sleep 1
    #./$0
    checkjenkins
  fi  
}
checkjenkins
