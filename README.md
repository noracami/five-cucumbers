# README

[![Deployed on Zeabur](https://zeabur.com/deployed-on-zeabur-dark.svg)](https://zeabur.com?referralCode=noracami&utm_source=noracami)

## TODO

1. bind jwt and user info
2. check cookie in iframe

### Integration Requirements

大平台出版整合文件

https://waterball.notion.site/v1-1-0-4020a50d26014f829492147af37db06f

1. register game ✔️

   - [x] register game

<details>
  <summary>request</summary>

```json
// POST /games
// Host: https://api.gaas.waterballsa.tw
// Authorization: Bearer {遊戲開發者的JWT}

{
  "uniqueName": "fivecucumber",
  "displayName": "黃瓜五兄弟",
  "shortDescription": "It is a trick-taking game with the goal of NOT winning the last trick!",
  "rule": "Win tricks but not the last, that gets you cucumbers! 5+ of those and you're out!\nhttps://boardgamegeek.com/boardgame/147768/five-cucumbers",
  "imageUrl": "https://gaas-five-cucumbers.zeabur.app/watermelon.png",
  "minPlayers": 1,
  "maxPlayers": 6,
  "frontEndUrl": "https://gaas-five-cucumbers.zeabur.app/frontend",
  "backEndUrl": "https://gaas-five-cucumbers.zeabur.app/api"
}
```

</details>

2. heartbeat api ✔️

   - [x] GET /api/health

3. create game api ✔️

<details>
  <summary>request</summary>

```json
// POST /games
// Host: {你的後端主機}
// Authorization: Bearer {房主的Jwt}

{
  "roomId": "room_385abe92e39a3",
  "players": [
    {
      "id": "6497f6f226b40d440b9a90cc",
      "nickname": "板橋金城武"
    },
    {
      "id": "6498112b26b40d440b9a90ce",
      "nickname": "三重彭于晏"
    },
    {
      "id": "6499df157fed0c21a4fd0425",
      "nickname": "蘆洲劉德華"
    },
    {
      "id": "649836ed7fed0c21a4fd0423",
      "nickname": "永和周杰倫"
    }
  ]
}
```

</details>

<details>
  <summary>response</summary>

```json
{
  "url": "https://{你的前端主機}/games/{gameId}"
}
```

</details>

4. JWT Authorization 📝

5. get user info action 📝

6. In frontend page, start game action 🚧

7. end game action ✔️

### endpoint

https://gaas-five-cucumbers.zeabur.app/
