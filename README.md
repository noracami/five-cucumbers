# README

[![Deployed on Zeabur](https://zeabur.com/deployed-on-zeabur-dark.svg)](https://zeabur.com?referralCode=noracami&utm_source=noracami)

https://gaas-five-cucumbers.zeabur.app/

### Integration Requirements

大平台出版整合文件

https://waterball.notion.site/v1-1-0-4020a50d26014f829492147af37db06f

1. register game 🚧

   - [ ] register game

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

2. heartbeat api ✔️

   - [x] GET /health

3. create game api 📝

4. JWT Authorization 📝

5. get user info action 📝

6. In frontend page, start game action 📝

7. end game action 📝
