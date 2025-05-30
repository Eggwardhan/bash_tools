#!/bin/bash

# 查找所有僵尸进程的父进程 ID
zombie_parents=$(ps -eo ppid,stat | grep ' Z' | awk '{print $1}')

# 遍历每个父进程 ID 并终止它们
for ppid in $zombie_parents; do
    echo "Killing parent process ID $ppid"
    kill -HUP $ppid 2>/dev/null
done
