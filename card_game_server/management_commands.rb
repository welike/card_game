class ManagementCommands
  attr_accessor :commands

  def initialize
    self.commands = {}

    register_management_commands
  end

  def register(klass)
    command = klass.new
    puts "register_command: added '#{command.command}' to class '#{command.class.name}'"
    commands[command.command] = command
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
  attr_accessor :command, :description, :handler

  def initialize(game_server, args)
    self.command     = 'abstract'
    self.description = 'An unimplemented mnanagement command'
    self.args        = args

    setup(game_server, args)
  end

  def setup(game_server, args)
    if command == 'abstract'
      puts "#{self.class.name} needs to set command and a description in an overriden setup method."
    end
  end

  def run
    puts "#{self.class.name} needs to override the run method."
  end
end

class BroadcastManagementCommand < ManagementCommand
  def setup(game_server, args)
    self.command = 'broadcast'
    self.description = 'Broadcast a message to all connected clients'
  end

  def run
    message = args[0]
    puts "Broadcasting '#{message}' to all connected clients"
    game_server.clients_send_content game_server.clients, "BROADCAST #{message}"
  end
end

class ClientManagementCommand < ManagementCommand
  def setup(game_server, args)
    self.command = 'client'
    self.description = 'Client related management commands'
  end

  def run
    subcommand = args[0]
    case subcommand
      when 'list'
        puts "client connections"
        if game_server.clients.size > 0
          game_server.clients.each do |num, client|
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
  def setup(game_server, args)
    self.command = 'game'
    self.description = 'Game related management commands'
  end

  def run
    subcommand = args[0]
    case subcommand
      when 'create'
        id = game_server.total_games += 1
        game_server.session_games += 1

        game = Game.new(id: id, type: game_server.settings.game_type, style: game_server.settings.game_style)
        puts "Created game #{game.id} of type '#{game.type}' and style '#{game.style}'."
        game_server.games[id] = game
      when 'list'
        puts "GAMES"
        game_server.games.each do |num, game|
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
  def setup(game_server, args)
    self.command     = 'help'
    self.description = 'Display command help'
  end

  def run
    puts "HELP"
    puts
    puts "Commands"
    puts '-'*80
    game_server.management_commands.each do |key, command|
      printf "%-15s %s\n", command[:command], command[:description]
    end
  end
end