module GameJob
  class CreateAiPlayerJob < ApplicationJob

    AI_PLAYERS = [
      {id: '6497f6f226b40d440b9a90cc', nickName: '板橋金城武', isAI: true},
      {id: '6498112b26b40d440b9a90ce', nickName: '三重彭于晏', isAI: true},
      {id: '6499df157fed0c21a4fd0425', nickName: '蘆洲劉德華', isAI: true},
      {id: '649836ed7fed0c21a4fd0423', nickName: '永和周杰倫', isAI: true},
      {id: 'ai:urad7dtbc6uexwcmi0mzl', nickName: '紅毛城之內', isAI: true},
      {id: 'ai:3gc3y41ju7331a9h18fx2', nickName: '王金平底鍋', isAI: true},
      {id: 'ai:9wnubu4uz2dq607see8td', nickName: '苗栗小五郎', isAI: true},
      {id: 'ai:mi4hmom37tlsabl2h57on', nickName: '南勢角金魚', isAI: true},
    ].freeze

    def perform(game, ai_player_number = 3)
      players = AI_PLAYERS.sample(ai_player_number)
      game.players = game.players + players
      game.save!
    end
  end
end
