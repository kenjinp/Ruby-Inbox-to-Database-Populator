require 'yaml'

puts 'This will generate the config file'
h = ''
puts 'Enter your gmail username...'
h['config']['username'] = gets.chomp
puts 'enter your password...'
h['config']['password'] = gets.chomp
puts 'making config file...'

puts h.to_yaml
open('config.yaml', 'w') { |f| YAML.dump(to_yaml, f) }
puts 'done'
