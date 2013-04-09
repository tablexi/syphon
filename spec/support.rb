require 'json'

class Support
  SPEC = File.expand_path(File.dirname(__FILE__))
  DATA = "#{SPEC}/data"

  def self.file(name)
    File.read("#{DATA}/#{name}")
  end

  def self.json(name)
    JSON.parse file("#{name}.json")
  end
end
