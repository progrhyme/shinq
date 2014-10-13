require 'optparse'
require 'yaml'
require 'shinq'

module Shinq
  class OptionParseError < StandardError; end

  class CLI
    def initialize(args=ARGV)
      parse_options(args)
      setup_db_connection
      bootstrap
    end

    def parse_options(args)
      @opts = {}
      parser = OptionParser.new do |opt|
        opt.on('--worker VALUE') do |v|
          @opts[:worker_name] = v
        end

        opt.on('--db-config VALUE') do |v|
          raise OptionParseError, "#{v} does not exist" unless File.exist?(v)
          @opts[:db_config] = YAML.load_file(v)
        end

        opt.on('--queue-database VALUE') do |v|
          raise OptionParseError, "#{v}'s settings does not exist" unless @opts[:db_config][v]
          @opts[:queue_db_settings] = @opts[:db_config][v]
        end

        opt.on('--require VALUE') do |v|
          @opts[:require] = v
        end
      end

      parser.parse!(args)
      @opts
    end

    def db_settings
      @opts[:queue_db_settings]
    end

    def setup_db_connection
      Shinq.setup_db_connection(db_settings)
    end

    def bootstrap
      return unless @opts[:require]

      if File.directory?(@opts[:require])
        require 'rails'
        require File.expand_path("#{@opts[:require]}/config/application.rb")
        require File.expand_path("#{@opts[:require]}/config/environment.rb")
      else
        require @opts[:require]
      end
    end

    end
  end
end
