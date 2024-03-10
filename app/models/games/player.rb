module Games
  class Player
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    attribute :id, :string
    attribute :email, :string
    attribute :nickname, :string
    attribute :is_ai, :boolean, default: false
    attribute :is_out, :boolean, default: false
    attribute :cucumbers, :integer, default: 0
    attribute :cards, default: -> { [] }
    attribute :game_id, :integer
    attribute :game_uuid, :string
    attribute :card_played, :integer, default: nil

    alias_attribute :is_ai?, :is_ai
    alias_attribute :is_out?, :is_out

    def self.build_from_game(game:, player_id:)
      player = new(game.players.find { |p| p["id"] == player_id })
      player.game_uuid = game.uuid
      player.game_id = game.id
      player
    end

    def inspect
      "Player: #{id}, Email: #{email}, Nickname: #{nickname}, Cucumbers: #{cucumbers}, Cards: #{cards}"
    end

    def to_json
      {
        id: id,
        email: email,
        nickname: nickname,
        is_ai: is_ai,
        is_out: is_out,
        cucumbers: cucumbers,
        cards: cards,
        card_played: card_played
      }
    end

    def user_info
      {
        id: id,
        email: email,
        nickname: nickname
      }
    end

    def deal_cards(cards)
      self.cards = cards.sort
      self
    end

    def nickName=(value)
      self.nickname = value
    end

    #
    # @param card [Integer] The card id to play
    def play_card(card = nil)
      # validate if player can play the card
      # 1. is it the player's turn?
      # 2. is the card in the player's hand?
      # 3. is the card valid to play?

      # 1. is it the player's turn?
      current_player_position = Utils::Redis.get("game:#{game_uuid}:current_player_position").to_i
      if id != Game.find(game_id).players[current_player_position]["id"]
        errors.add(:base, "It's not your turn")
        return self
      end

      last_played_card = Utils::Redis.read_last_played_card(game_uuid)
      smallest_number = cards.map { |c| Games::Card.new(id: c).numbers }.min

      # if the player is an AI, then the card is chosen by the AI
      card = choose_ai_card(last_played_card, smallest_number) if is_ai?

      # 2. is the card in the player's hand?
      if cards.index(card).nil?
        errors.add(:base, "Card not found")
        return self
      end

      # 3. is the card valid to play?
      # compare to the last played card
      # ++ valid card ++ is either the greater or the same number
      # or the smallest number in the hand
      card = Games::Card.new(id: card)
      if !card.playable?(last_played_card, smallest_number)
        errors.add(:base, "Invalid card")
        return self
      end

      self.card_played = card.id
      cards.delete(card)
      Utils::Redis.play_card_to_trick(game_uuid, card.id)


      game = Game.find(game_id)
      game_notifier = Utils::Notify.new(game)
      game_notifier.update_game_event_logs
      game_notifier.update_player_actions(self)
      game.wrap_players.each { |player| game_notifier.update_player_stats(player.id) }
    end

    def is_out?
      is_out
    end

    def is_ai?
      is_ai
    end

    private

    def choose_ai_card(last_played_card, smallest_number)
      ai_card_candidates = cards.map { |c| Games::Card.new(id: c) }
      ret = ai_card_candidates.sample
      ret = ai_card_candidates.sample unless ret.playable?(last_played_card, smallest_number)
      ret.id
    end
  end
end
