require 'gmail'
require 'yaml'
require 'nokogiri'
require 'open-uri'

class Order
  attr_accessor :name,
                :title,
                :cell_number,
                :ambit_handle,
                :image,
                :coupon_code

  def initialize(name, title, cell_number, ambit_handle, image, coupon_code)
    @name = name
    @title = title
    @cell_number = cell_number
    @ambit_handle = ambit_handle
    @image = image
    @coupon_code = coupon_code
  end

end

def read_config
  config = YAML.load_file("config.yaml")
  @username = config["config"]["username"]
  @password = config["config"]["password"]
  @label = config["config"]["label"]
end

read_config

begin
  puts 'attempting to connect to ' + @username + '@gmail.com'
  Gmail.new(@username, @password) do |gmail|
      puts 'connection established'
      #use peek to make emails not be automatically marked as read
      gmail.peek = true
      if @label == "none"
        inbox = gmail.inbox
        boxname = 'inbox'
      else
        inbox = gmail.mailbox(@label)
        boxname = @label + ' box'
      end
      number_unread = inbox.count(:unread)
      if number_unread < 1
        abort("There are no new messages in the " + boxname)
      end
      puts "there are " + number_unread.to_s + " unread emails in the " + boxname
      inbox.emails(:unread).each do |email|
        puts '///' * 30
        #puts email.body
        doc = Nokogiri::HTML(email.body.to_s)
        table = doc.at('table')
        table.search('b').each do |t|
          puts t.text
          puts t.next.next.text
        end
      end
  end

rescue Net::IMAP::NoResponseError
  puts 'connection failed, check your credentials and connectivity'
end
