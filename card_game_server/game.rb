class Game
  attr_accessor :id, :type, :style
  attr_accessor :clients
  attr_accessor :status

  def initialize(options = {})
    self.id    = options[:id]
    self.type  = options[:type]
    self.style = options[:style]

    self.status  = :creating
    self.clients = []
  end
end