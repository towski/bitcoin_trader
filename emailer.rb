require_relative 'application'
require 'mail'
password = YAML.load_file('email_password.yml')["password"]
options = { 
  :address              => "smtp.gmail.com",
  :user_name            => 'towski@gmail.com',
  :password             => password,
  :authentication       => 'plain',
  :enable_starttls_auto => true
}

Mail.defaults do
  delivery_method :smtp, options
end

last_trade_id = MyTrade.last.id

def send_email(last_trade)   
  puts "sending email"
  Mail.deliver do
    to 'towski@gmail.com'
    from 'btce+towski@gmail.com'
    subject "latest trade btce @ #{last_trade.price}"
    body last_trade.attributes.inspect
  end
end

loop do
  trade = MyTrade.last
  puts "checking #{trade.id}"
  if trade.id > last_trade_id
    send_email(trade)
    last_trade_id = trade.id
  end
  sleep 5
end
