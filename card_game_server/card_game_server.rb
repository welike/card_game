require_relative 'game'
require_relative 'management_commands'
require_relative 'settings'

require 'yaml'

class CardGameServer
  attr_accessor :management_commands, :settings, :server
  attr_accessor :clients, :games
  attr_accessor :session_connections, :session_games
  attr_accessor :total_connections, :total_games

  def initialize
    setup
    main
  end

  def setup
    # Initializations
    self.clients  = {}
    self.management_commands = ManagementCommands.new
    self.games    = {}
    self.session_connections = 0
    self.session_games       = 0
    self.total_connections   = 0
    self.total_games         = 0

    # Settings
    self.settings = Settings.new
    settings.bind_address = '127.0.0.1'
    settings.bind_port    = 3434
    settings.game_type    = :poker
    settings.game_style   = :five_card_draw

    load_config
    load_data
  end

  def start_server
    require 'socket'
    self.server = TCPServer.new(settings.bind_address, settings.bind_port)
    puts "Listening for new connections on #{settings.bind_address}:#{settings.bind_port}"
  end

  def main
    puts "Starting pokerd (bind address: #{settings.bind_address}, bind port: #{settings.bind_port}, game type: #{settings.game_type}, game style: #{settings.game_style})"

    start_server

    Thread.abort_on_exception = true
    Thread.start do
      management_loop
    end

    loop do
      Thread.start(server.accept) do |client|
        puts "client connected - #{client.peeraddr}"
        self.total_connections += 1
        clients[total_connections] = client
        client.puts 'Hello!'
        game_loop(client)
        client.puts 'Goodbye.'
        client.close
      end
    end
  end

  # loop handling

  def game_loop(client)
    connected = true
    while connected
      client_send_content(client, 'GA')
      received = client_receive_content(client)
      puts "client sent '#{received}'"

      if %w[q quit].include?(received)
        puts "client asked to quit"
        connected = false
      end
    end
  end

  def management_loop
    running = true
    while running
      print "> "
      input = gets.chomp
      command, args = extract_command(input)
      management_commands.handle_management_command(self, command, *args) if command

      running = false if %w[q quit].include?(command)
    end
    command_shutdown
  end

  # client

  def client_receive_content(client)
    client.gets.chomp
  end

  def client_send_content(client, content = "")
    client.puts content
  end

  # all clients

  def clients_send_content(clients, content = "")
    clients.each do |num, client|
      client_send_content client, content
    end
  end

  def extract_command(input)
    arr = input.split(' ', 2)
    arr
  end

  # config/data

  def load_config
    filename = 'config.yml'
    puts 'Loading config...'
    self.settings = YAML.load_file(filename) if File.exists?(filename)
  end

  def save_config
    filename = 'config.yml'
    puts "Saving config... (#{filename})"
    File.open(filename, 'w') { |f| f.write settings.to_yaml }
  end

  def load_data
    filename = 'data.yml'
    puts 'Loading data...'

    if File.exists?(filename)
      data = YAML.load_file(filename)

      self.total_connections = data[:total_connections]
      self.total_games       = data[:total_games]
    end
  end

  def save_data
    filename = 'data.yml'
    puts "Saving data... (#{filename})"
    data = {
      last_connections: session_connections,
      last_games: session_games,
      total_connections: total_connections,
      total_games: total_games
    }
    File.open(filename, 'w') { |f| f.write data.to_yaml }
  end
end

CardGameServer.new