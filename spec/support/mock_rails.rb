require 'pathname'

unless defined?(Rails)
  module Rails
    def self.logger
    end

    def self.root
      Pathname.new('.')
    end
  end
end
