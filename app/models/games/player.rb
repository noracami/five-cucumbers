module Games
  class Player
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :id, :string
    attribute :email, :string
    attribute :nickname, :string
    attribute :is_ai, :boolean, default: false
    attribute :is_out, :boolean, default: false
    attribute :cucumbers, :integer, default: 0
    attribute :cards, default: -> { [] }
    attribute :game_uuid, :string
    attribute :card_played, :integer, default: nil

    alias_attribute :is_ai?, :is_ai
    alias_attribute :is_out?, :is_out

    def self.build_from_game(game:, player_id:)
      player = new(game.players.find { |p| p["id"] == player_id })
      player.game_uuid = game.uuid
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
    def play_card(card)
      self.card_played = card
      cards.delete(card)
    end
  end
end
