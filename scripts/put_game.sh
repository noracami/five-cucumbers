#!/usr/bin/env bash

host=https://api.gaas.waterballsa.tw
WATERBALL_JWT=$token
# gameId=$gameId

curl -vX 'PUT' \
        $host/games/$gameId \
        -H 'accept: */*' \
        -H "Authorization: Bearer $WATERBALL_JWT" \
        -H 'Content-Type: application/json' \
        -d \
        '{
        "uniqueName": "fivecucumber",
        "displayName": "黃瓜五兄弟",
        "shortDescription": "It is a trick-taking game with the goal of NOT winning the last trick!",
        "rule": "Try to avoid getting cucumbers more than 5, or you are out!",
        "imageUrl": "https://gaas-five-cucumbers.zeabur.app/watermelon.png",
        "minPlayers": 1,
        "maxPlayers": 6,
        "frontEndUrl": "",
        "backEndUrl": "https://gaas-five-cucumbers.zeabur.app/api"
        }' \
        | jq

# Path: scripts/put_game.sh
