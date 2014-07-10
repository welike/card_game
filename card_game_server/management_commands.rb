class ManagementCommands
  attr_accessor :commands

  def initialize
    self.commands = {}

    register_management_commands
  end

  def register_command(command, klass, options = {})
    puts "register_command: added '#{command}' to call method '#{method}'"
    commands[command] = {
      command: command,
      klass: klass,
      description: options[:description] || ''
    }
  end

  def register_management_commands
    puts 'Registering management commands...'
    register_command('broadcast', 'command_broadcast', description: 'Send a message to all connected clients')
    register_command('game_create', 'command_game_create', description: 'Create a game')
    register_command('game_list', 'command_game_list', description: 'List current and previous games')
    register_command('clients', 'command_list_clients', description: 'List current and previous client connections')
    register_command('help', HelpManagementCommand, description: 'Display command help')
    register_command('shutdown', 'command_shutdown', description: 'Shutdown server immediately')
    puts
  end
end

class ManagementCommand
  attr_accessor :command, :description, :handler

  def initialize(game_server, args)
    self.command     = 'abstract'
    self.description = 'An unimplemented mnanagement command'
    self.args        = args

    if command == 'abstract'
      puts "#{self.class.name} needs to set command and a description."
    end
  end

  def run
    puts "#{self.class.name} needs to override the run method."
  end
end

class HelpManagementCommand < ManagementCommand
  def initialize(game_server, args)
    super
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