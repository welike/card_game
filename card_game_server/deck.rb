class Deck
  attr_accessor :cards
  attr_accessor :card_structure
  attr_accessor :stack

  def initialize
    self.cards = []
    self.card_structure = %w[1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4 5 5 5 5 6 6 6 6 7 7 7 7 8 8 8 8 9 9 9 9 10 10 10 10 J J J J Q Q Q Q K K K K A A A A]

    card_structure.each do |card_symbol|
      cards << Card.new(card_symbol)
    end

    self.stack = cards.clone
  end

  def shuffle(count=3)
    count.times.each do
      puts "Shuffling deck..."
      self.stack = stack.shuffle
      puts "Deck became: #{to_s}"
    end
  end

  def to_s(format=:remaining)
    case format
      when :remaining
        stack.map(&:symbol).join(' ')
      when :structure
        card_structure.join(' ')
    end
  end
end