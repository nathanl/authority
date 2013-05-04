require 'pathname'

module Rails
  def self.root
    Pathname.new('.')
  end
end
