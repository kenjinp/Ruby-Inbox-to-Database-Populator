require 'gmail'
require 'yaml'

#open('config.cfg') { |f| test_data = YAML.load(f) }
#open('config.cfg') { |f| puts f.read }

def read_config
  config = YAML.load_file("config.yaml")
  @username = config["config"]["username"]
  @password = config["config"]["password"]
end

read_config

#Gmail.new(@username, @password) do |gmail|
#  inbox = gmail.inbox
  #inbox.emails(:unread).each do |email|
  #  puts email.body
  #end
#end
