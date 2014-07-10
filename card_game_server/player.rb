class Player
  attr_accessor :client, :user

  def initialize(client, user)
    self.client = client
    self.user   = user
  end
end