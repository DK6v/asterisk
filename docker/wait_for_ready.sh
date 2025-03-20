#!/bin/bash

IFS=" " read -r -a process_list <<< "$*"

if [ ${#process_list[@]} -eq 0 ]; then
  echo "Usage: $0 <process_name> [...]"
  exit 1
fi

while [ ${#process_list[@]} -ne 0 ]; do
  for process_name in "${process_list[@]}"; do
    status=$(supervisorctl status "$process_name" | awk '{print $2}')
    if [ "$status" = "RUNNING" ]; then
      echo "Process $process_name is running."
      process_list=("${process_list[@]:1}")
    elif [ "$status" = "STARTING" ]; then
      echo "Process $process_name is starting..."
      sleep 1
      break
    else
      echo "Process $process_name is not running. Current status: $status"
      exit 1
    fi
  done
done
