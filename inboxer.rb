require 'gmail'
require 'yaml'
require 'nokogiri'
require "active_record"

def readConfig
  #return a hash or something
  config = YAML.load_file("config.yaml")["config"]
end

config = readConfig

ActiveRecord::Base.establish_connection(
  environment: config["database"]["environment"],
  adapter: config["database"]["adapter"],
  encoding: config["database"]["encoding"],
  database: config["database"]["database"],
#  username: config["database"]["username"],
#  password: config["database"]["password"]
)

class Order < ActiveRecord::Base
end

def parser(email)
  #create the parsable doc
  doc = Nokogiri::HTML(email.body.to_s)
  table = doc.at('table')

  #read the text associated with the bold text in an email
  def textAtNode(node, number)
    #text may not be incoded correctly, may try to .force_encoding in the future
    mytext = node.css('b')[number].next.next.text.to_s.gsub("=\n", '').gsub("=0A", '')
    #
    mytext = (mytext.blank? ? nil : mytext)
    #
  end

  #this is the only exceptional peice of data that must be treated with special cases
  if textAtNode(table, 5).include? 'Use the file that I upload (below) OR please use:'
    # if they chose to upload their own file, use the link
    image = textAtNode(table, 6)
    # if they didn't upload an image so there is no link, choose a default for them
    image = (image.blank? ? 'Free Energy' : image)
  else
    #otherwise they must have chosen a default image, so just use that text
    image = textAtNode(table, 5)
  end

  def video_url( handle )
    "#{handle}.energy526.com"
  end

  def website( handle )
    "#{handle}.myambit.com"
  end

  def check_rates_url( handle )
    "#{handle}.myambit.com/rates-and-plans"
  end

  def get_more_info_url( handle )
    "#{handle}.myambit.com/get-more-info"
  end

  def handleizer( raw_handle )
    raw_handle.split().first
  end

  name = textAtNode(table, 0)
  title = textAtNode(table, 1)
  cell_number = textAtNode(table, 2)
  email = textAtNode(table, 3)
  ambit_handle = handleizer( textAtNode(table, 4) )
  alternate_video_url = textAtNode(table, 7)
  video_url = alternate_video_url ? nil : video_url( ambit_handle )
  alternate_keyword = textAtNode(table, 8)
  alternate_web = textAtNode(table, 9)
  coupon_code = textAtNode(table, 10)
  referral = textAtNode(table, 11)
  pic_url = image
  website =  alternate_web ? nil : website( ambit_handle )
  check_rates_url =  check_rates_url( ambit_handle )
  get_more_info_url = get_more_info_url( ambit_handle )

  email_data = {
    name: name,
    title: title,
    cell_number: cell_number,
    email: email,
    ambit_handle: ambit_handle,
    alternate_video_url: alternate_video_url,
    video_url: textAtNode(table, 7) ? nil : video_url( textAtNode(table, 4) ),
    alternate_keyword: textAtNode(table, 8),
    alternate_web: textAtNode(table, 9),
    coupon_code: textAtNode(table, 10),
    referral: textAtNode(table, 11),
    pic_url: image,
    website: textAtNode(table, 9) ? nil : website( textAtNode(table, 4) ),
    check_rates_url: check_rates_url( textAtNode(table, 4) ),
    get_more_info_url: get_more_info_url( textAtNode(table, 4) ),
    email_to_client_sent: false
  }

  email_data

end #end parser

#set up gmail connection, preforms something on each unread email,
#set peek to true if you don't want to automatically mark it as read
def getEmails( config )

  username = config["username"]
  password = config["password"]
  label = config["label"]
  peek = config["peek"]


  begin
    puts 'attempting to connect to ' + username + '@gmail.com'
    gmail = Gmail.new(username, password)
    puts 'connection established'
    #use peek to make emails not be automatically marked as read
    gmail.peek = (peek == 'true' ? true : false)

    if label == "none"
      inbox = gmail.inbox
      boxname = 'inbox'
    else
      inbox = gmail.mailbox(label)
      boxname = label + ' box'
    end
    number_unread = inbox.count(:unread)
    if number_unread < 1
      abort("There are no new messages in the " + boxname)
    end
    p "there are " + number_unread.to_s + " unread emails in the " + boxname
    emails = inbox.emails(:unread).map { |email| parser(email) }

  rescue Net::IMAP::NoResponseError
    puts 'connection failed, check your config file for incorrect credentials'
    puts 'perhaps you opted to use a label that doesn\'t exist, try "none" instead'
    []
  end
end
emails = getEmails( config )
emails.each { |email| Order.find_or_create_by!( email ) }

