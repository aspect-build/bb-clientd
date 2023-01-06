#!/bin/sh

BASE_DIRECTORY="/buildbarn/.cache/bb_clientd"
while [[ ! -d "${BASE_DIRECTORY}/filepool" || ! -d "${BASE_DIRECTORY}/grpc"  || ! -d "${BASE_DIRECTORY}/log" ]]
do
    echo "Directories do not exist. Waiting"
    sleep 1
done

chown -R circleci:circleci /buildbarn/.cache/bb_clientd/
