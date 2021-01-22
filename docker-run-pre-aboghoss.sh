#!/usr/bin/env bash

docker run \
--name pre-processing \
-v /Users/aboghoss/Downloads/MTS015_PR500_reprocess:/data \
-e AWS_BATCH_JOB_ARRAY_INDEX=0 \
-it cmap/clue-mts \
-i /data \
-o /data \
-t "0" \
-p /data \
-a "PR500"
