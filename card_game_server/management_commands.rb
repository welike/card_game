class ManagementCommands
  attr_accessor :commands

  def initialize
    self.commands = {}

    register_management_commands
  end

  def handle_management_command(server, command, *args)
    nearest_command = identify_nearest_command(command)
    if nearest_command.is_a?(Array) && nearest_command.size > 1
      puts "There are several matching commands: #{nearest_command.join(', ')}"
    else
      klass = commands[nearest_command]
      if klass
        klass.new(server, args)
      elsif command == ''
        # Enter was pressed without submitting a command
      else
        puts "Unknown command: #{command}"
      end
    end
  end

  private

  def identify_nearest_command(command)
    commands.keys.find { |e| /^#{command}/ =~ e }
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
    register(ShutdownManagementCommand)
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
      when 'halt'
        id = args[1].to_i
        game = server.games[id]
        if game
          puts "Halting game #{game.id}"
          game.halt
        else
          puts "No game exists with #{id}"
        end
      when 'info'
        id   = args[1].to_i
        game = server.games[id]
        if game
          puts "GAME #{id}"
          puts "type: #{game.type}  style: #{game.style}"
          puts "status: #{game.status}"
          puts
          puts "DECK"
          puts
          puts "  #{game.deck}"
          puts
          puts "0 players"
          puts
        else
          puts "No game exists with #{id}"
        end
      when 'list'
        puts "GAMES"
        server.games.each do |num, game|
          puts "#{game.id}: #{game.type}/#{game.style}: #{game.status}: #{game.players.size} players"
        end
      when '', nil
        puts "HELP game"
        puts
        puts "game create    Creates a new game matching the server's configured game type and style"
        puts "game list      Lists the previous and current games"
        puts
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

  def run
    puts 'Shutdown initiated...'
    server.save_config
    server.save_data
    puts 'Shutdown.'
    exit
  end
end
