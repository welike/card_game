class ManagementCommands
  attr_accessor :commands

  def initialize
    self.commands = {}

    register_management_commands
  end

  def handle_management_command(server, command, *args)
    klass = commands[command]
    if klass
      klass.new(server, args)
    elsif command == ''
      # Enter was pressed without submitting a command
    else
      puts "Unknown command: #{command}"
    end
  end

  def register(klass)
    puts "register_command: added '#{klass::COMMAND}' to class '#{klass.name}'"
    commands[klass::COMMAND] = klass
  end

  def register_management_commands
    puts 'Registering management commands...'
    register(BroadcastManagementCommand)
    register(ClientManagementCommand)
    register(GameManagementCommand)
    register(HelpManagementCommand)
    puts
  end
end

# Acts as an abstract class for all management commands
class ManagementCommand
  COMMAND     = 'abstract'
  DESCRIPTION = 'An unimplemented management command'

  attr_accessor :server, :args

  def initialize(server, args)
    self.server = server
    self.args   = args

    run
  end

  def run
    puts "#{self.class.name} needs to override the run method."
  end
end

class BroadcastManagementCommand < ManagementCommand
  COMMAND     = 'broadcast'
  DESCRIPTION = 'Broadcast a message to all connected clients'

  def run
    message = args[0]
    puts "Broadcasting '#{message}' to all connected clients"
    server.clients_send_content server.clients, "BROADCAST #{message}"
  end
end

class ClientManagementCommand < ManagementCommand
  COMMAND     = 'client'
  DESCRIPTION = 'Client related management commands'

  def run
    subcommand = args[0]
    case subcommand
      when 'list'
        puts "client connections"
        if server.clients.size > 0
          server.clients.each do |num, client|
            puts "#{num}: #{client.peeraddr(true)}"
          end
        else
          puts "none."
        end
      else
        puts "Unknown command: client #{subcommand}"
    end
  end
end

class GameManagementCommand < ManagementCommand
  COMMAND     = 'game'
  DESCRIPTION = 'Game related management commands'

  def run
    subcommand = args[0]
    case subcommand
      when 'create'
        id = server.total_games += 1
        server.session_games += 1

        game = Game.new(id: id, type: server.settings.game_type, style: server.settings.game_style)
        puts "Created game #{game.id} of type '#{game.type}' and style '#{game.style}'."
        server.games[id] = game
      when 'list'
        puts "GAMES"
        server.games.each do |num, game|
          puts "#{game.id}: #{game.type}/#{game.style}: 0 players"
        end
      when ''
        puts "create/list"
      else
        puts "Unknown command: game #{subcommand}"
    end
  end
end

class HelpManagementCommand < ManagementCommand
  COMMAND     = 'help'
  DESCRIPTION = 'Display command help'

  def run
    puts "HELP"
    puts
    puts "Commands"
    puts '-'*80
    server.management_commands.commands.each do |key, klass|
      printf "%-15s %s\n", klass::COMMAND, klass::DESCRIPTION
    end
  end
end

class ShutdownManagementCommand < ManagementCommand
  COMMAND     = 'shutdown'
  DESCRIPTION = 'Shutdown the server'

  def setup
    puts 'Shutdown initiated...'
    server.save_config
    server.save_data
    puts 'Shutdown.'
    exit
  end
end
