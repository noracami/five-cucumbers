module GameJob
  class AddAiPlayersJob < ApplicationJob

    AI_PLAYERS = [
      {id: '6497f6f226b40d440b9a90cc', nickname: '板橋金城武', is_ai: true},
      {id: '6498112b26b40d440b9a90ce', nickname: '三重彭于晏', is_ai: true},
      {id: '6499df157fed0c21a4fd0425', nickname: '蘆洲劉德華', is_ai: true},
      {id: '649836ed7fed0c21a4fd0423', nickname: '永和周杰倫', is_ai: true},
      {id: 'ai:urad7dtbc6uexwcmi0mzl', nickname: '紅毛城之內', is_ai: true},
      {id: 'ai:3gc3y41ju7331a9h18fx2', nickname: '王金平底鍋', is_ai: true},
      {id: 'ai:9wnubu4uz2dq607see8td', nickname: '苗栗小五郎', is_ai: true},
      {id: 'ai:mi4hmom37tlsabl2h57on', nickname: '南勢角金魚', is_ai: true},
    ].freeze

    def perform(game, ai_player_number = 3)
      AI_PLAYERS
        .sample(ai_player_number)
        .map { |player| Games::Player.new(player) }
        .each { |player| Utils::Notify.push_player_joined_event(game, player.nickname, 'ai_joined') }
        .then { |players| game.players = game.players + players.map(&:to_json) }
      game.state = :player_number_confirmed
      game.save!
    end
  end
end
