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

    alias_attribute :is_ai?, :is_ai
    alias_attribute :is_out?, :is_out

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
        cards: cards
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
      self.cards = cards
      self
    end

    def nickName=(value)
      self.nickname = value
    end
  end
end
