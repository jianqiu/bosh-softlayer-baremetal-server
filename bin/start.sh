#!/bin/bash

nohup bin/api_ctl 1 >> logs/api_ctl.stdout 2 >> logs/api_ctl.stderr &
nohup bin/worker_ctl 1 >> logs/worker_1.stdout 2 >> logs/worker_1.stderr &
nohup bin/worker_ctl 1 >> logs/worker_2.stdout 2 >> logs/worker_2.stderr &
nohup bin/worker_ctl 1 >> logs/worker_3.stdout 2 >> logs/worker_3.stderr &
nohup bin/worker_ctl 1 >> logs/worker_4.stdout 2 >> logs/worker_4.stderr &
nohup bin/worker_ctl 1 >> logs/worker_5.stdout 2 >> logs/worker_5.stderr &
nohup bin/worker_ctl 1 >> logs/worker_6.stdout 2 >> logs/worker_6.stderr &
nohup bin/worker_ctl 1 >> logs/worker_7.stdout 2 >> logs/worker_7.stderr &
nohup bin/worker_ctl 1 >> logs/worker_8.stdout 2 >> logs/worker_8.stderr &
nohup bin/worker_ctl 1 >> logs/worker_9.stdout 2 >> logs/worker_9.stderr &
