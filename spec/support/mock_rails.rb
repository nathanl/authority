require 'pathname'

unless defined?(Rails)
  module Rails
    def self.logger
      @logger ||= Logger.new(STDOUT)
    end

    def self.root
      Pathname.new('.')
    end
  end
end

def undefine_rails
  Object.send(:remove_const, :Rails)                  # Pretend Rails never existed
  $LOADED_FEATURES.delete(File.expand_path(__FILE__)) # Pretend we've never required this file before.
end
