#!/usr/bin/env bash

host=https://api.gaas.waterballsa.tw
host=https://lobby.gaas.waterballsa.tw/api/internal
roomId=$1
WATERBALL_JWT=$token

curl -v -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $WATERBALL_JWT" \
        $host/rooms/$roomId:endGame \
        | jq
