module Games
  class Card
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :id, :integer
    attribute :cucumbers, :integer
    attribute :numbers, :integer

    def initialize(params)
      super(params)

      case (numbers = ((params[:id] - 1) / 4) + 1)
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
  end
end
