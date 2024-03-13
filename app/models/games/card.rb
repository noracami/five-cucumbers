module Games
  class Card
    include ActiveModel::Model
    include ActiveModel::Attributes
    include Comparable

    attribute :id, :integer
    attribute :cucumbers, :integer
    attribute :numbers, :integer

    def initialize(params)
      super(params)

      case (numbers = ((id - 1) / 4) + 1)
      when 1
        self.numbers = numbers
        self.cucumbers = 0
      when 2..5
        self.numbers = numbers
        self.cucumbers = 1
      when 6..9
        self.numbers = numbers
        self.cucumbers = 2
      when 10..13
        self.numbers = numbers
        self.cucumbers = 3
      when 14
        self.numbers = numbers
        self.cucumbers = 4
      when 15
        self.numbers = numbers
        self.cucumbers = 5
      else
        raise "Invalid card id: #{id}"
      end
    end

    def inspect
      "Card: #{id}, Cucumbers: #{cucumbers}, Numbers: #{numbers}"
    end

    def <=>(another_card)
      numbers <=> another_card.numbers
    end

    def playable?(largest_card_in_the_trick, cards)
      # card is first played
      if largest_card_in_the_trick.nil?
        return true
      # card is larger or equal to the largest card in the trick
      elsif self >= largest_card_in_the_trick
        return true
      # no card is larger or equal to the largest card in the trick and the choose card is the smallest
      elsif (cards.all? { |card| card < largest_card_in_the_trick.numbers }) && numbers == cards.min
        return true
      end

      false
    end
  end
end
