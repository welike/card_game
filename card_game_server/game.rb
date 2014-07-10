class Game
  attr_accessor :id, :type, :style
  attr_accessor :deck, :players
  attr_accessor :status

  def initialize(options = {})
    self.id    = options[:id]
    self.type  = options[:type]
    self.style = options[:style]

    self.status  = :creating
    self.players = []

    self.deck = Deck.new

    self.status = :waiting_to_start
  end

  def halt
    self.status = :halted
    save
  end

  def start
    self.status = :active

    deck.shuffle
  end

  def complete
    self.status = :complete
    save
  end

  def save
    games_path = "games"
    Dir.mkdir games_path if not File.exists?(games_path)

    filename = File.join(games_path, "#{id}.yml")
    File.open(filename, 'w') { |f| f.write self.to_yaml }
  end
end