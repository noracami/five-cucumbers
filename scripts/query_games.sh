#!/usr/bin/env bash

host=https://api.gaas.waterballsa.tw
WATERBALL_JWT=$token

curl -vX 'GET' \
        $host/games \
        -H 'accept: */*' \
        -H "Authorization: Bearer $WATERBALL_JWT" \
        | jq

