class Card
  attr_accessor :symbol

  def initialize(symbol)
    self.symbol = symbol
  end

  def to_s
    symbol.to_s
  end
end