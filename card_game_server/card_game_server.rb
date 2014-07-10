require_relative 'game'
require_relative 'management_commands'
require_relative 'settings'

require 'yaml'

class CardGameServer
  attr_accessor :commands, :settings, :server
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
    self.commands = {}
    self.games    = {}
    self.session_connections = 0
    self.session_games       = 0
    self.total_connections   = 0
    self.total_games         = 0

    register_management_commands

    # Settings
    self.settings = Settings.new
    settings.bind_address = '127.0.0.1'
    settings.bind_port    = 3434
    settings.game_type    = :poker
    settings.game_style   = :five_card_draw
  end

  def register_management_commands
    puts 'Registering management commands...'
    register_command('broadcast', 'command_broadcast', description: 'Send a message to all connected clients')
    register_command('game_create', 'command_game_create', description: 'Create a game')
    register_command('game_list', 'command_game_list', description: 'List current and previous games')
    register_command('clients', 'command_list_clients', description: 'List current and previous client connections')
    register_command('help', 'command_help', description: 'Display command help')
    register_command('shutdown', 'command_shutdown', description: 'Shutdown server immediately')
    puts
  end

  def start_server
    require 'socket'
    self.server = TCPServer.new(settings.bind_address, settings.bind_port)
    puts "Listening for new connections on #{settings.bind_address}:#{settings.bind_port}"
  end

  def main
    # Main
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

  def game_loop(client)
    connected = true
    while connected
      client_send_content(client, 'GA')
      received = client_receive_content(client)
      puts "client sent '#{received}'"

      if %w[q quit].include?(received)
        puts "client elected to quit"
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
      handle_management_command(command, *args) if command

      running = false if %w[q quit].include?(command)
    end
    command_shutdown
  end

  def client_receive_content(client)
    client.gets.chomp
  end

  def client_send_content(client, content = "")
    client.puts content
  end

  def clients_send_content(clients, content = "")
    clients.each do |num, client|
      client_send_content client, content
    end
  end

  def command_shutdown(args)
    puts 'Shutdown initiated...'
    save_config
    save_data
    puts 'Shutdown.'
    exit
  end

  def extract_command(input)
    arr = input.split(' ', 2)
    arr
  end

  def handle_management_command(command, *args)
    command_item = commands[command]
    if command_item
      self.send(command_item[:method], args) if self.respond_to? command_item[:method]
    elsif command == ''
      # Enter was pressed without submitting a command
    else
      puts "Unknown command: #{command}"
    end
  end

  def load_config
    puts 'Loading config...'
  end

  def save_config
    filename = 'config.yml'
    puts "Saving config... (#{filename})"
  end

  def load_data
    puts 'Loading data...'
    data = File
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