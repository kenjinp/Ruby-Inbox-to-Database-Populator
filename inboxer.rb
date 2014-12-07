require 'gmail'
require 'yaml'
require 'nokogiri'

def readConfig
  #return a hash or something
  config = YAML.load_file("config.yaml")

  config_arr = {
    username: config["config"]["username"],
    password: config["config"]["password"],
    label: config["config"]["label"],
    peek: config["config"]["peek"]
  }

  config_arr
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

  email_data = {
    name: textAtNode(table, 0),
    title: textAtNode(table, 1),
    cell: textAtNode(table, 2),
    customer_email: textAtNode(table, 3),
    ambit_handle: textAtNode(table, 4),
    image: image,
    alternate_video: textAtNode(table, 7),
    alternate_keyword: textAtNode(table, 8),
    alternate_web: textAtNode(table, 9),
    coupon_code: textAtNode(table, 10),
    referral: textAtNode(table, 11)
  }

  email_data

end #end parser

#set up gmail connection, preforms something on each unread email,
#set peek to true if you don't want to automatically mark it as read
def getEmails

  username = readConfig[:username]
  password = readConfig[:password]
  label = readConfig[:label]
  peek = readConfig[:peek]


  begin
    puts 'attempting to connect to ' + username + '@gmail.com'
    Gmail.new(username, password) do |gmail|
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
        inbox.emails(:unread).each do |email|
          puts parser(email)
        end
    end

  rescue Net::IMAP::NoResponseError
    puts 'connection failed, check your config file for incorrect credentials'
    puts 'perhaps you opted to use a label that doesn\'t exist, try "none" instead'
  end
end

getEmails
