require_relative 'migrator'
require 'yaml'

module Command
  class CLI < Escort::ActionCommand::Base
    def execute
      begin
      setting_file = YAML.load_file(global_options[:file])
      Migrator.new(setting_file).run(command_name, command_options)
      rescue => exception
        puts exception.backtrace
        raise # always reraise
      end
    end
  end
end
