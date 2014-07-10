class Game
  attr_accessor :id, :type, :style
  attr_accessor :clients, :deck, :players
  attr_accessor :status

  def initialize(options = {})
    self.id    = options[:id]
    self.type  = options[:type]
    self.style = options[:style]

    self.status  = :creating
    self.clients = []
    self.players = []

    self.deck = Deck.new
    deck.shuffle

    self.status = :waiting_to_start
  end

  def halt
    self.status = :halted
  end

  def start
    self.status = :active
  end

  def complete
    self.status = :complete
  end

end