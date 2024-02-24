#!/usr/bin/env bash

host=https://api.gaas.waterballsa.tw
roomId=$1
WATERBALL_JWT=$token

curl -v -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $WATERBALL_JWT" \
        $host/rooms/$roomId:endGame \
        | jq
