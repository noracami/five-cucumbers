module GamesHelper
  class ::Integer
    def to_card_number = Games::Card.new(id: self).numbers
  end
end
