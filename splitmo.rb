require 'oauth'
require 'webrick'
require 'json'
require 'yaml'
require 'net/smtp'
require 'tlsmail'
require 'open-uri'

private
def get_user(user_id,members)
  return members.select{|m|m["id"]==user_id}.first
end

def send_email smtp_config, from, to, mailtext
  begin 
    Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
    Net::SMTP.start(smtp_config["smtp_server"], 
                    smtp_config["port"], 
                    smtp_config["helo"], 
                    smtp_config["username"],
                    smtp_config["password"],
                    smtp_config["authentication"]) do |smtp|
      smtp.send_message mailtext, from, to
    end
  rescue => e  
    raise "Exception occured: #{e} "
    exit -1
  end  
end

public
CONFIG_LOCATION= ARGV[0] || "./.splitmo"
begin
  config = YAML.load(File.open(CONFIG_LOCATION,"r"))
rescue => e  
  raise "Exception occured reading config file: #{e} "
  exit -1
end  
consumer=OAuth::Consumer.new(config["splitwise_client"]["key"],
                             config["splitwise_client"]["secret"],
                             :site=>"https://secure.splitwise.com",
                             :access_token_path=>"/api/v2.0/get_access_token",
                             :request_token_path=>"/api/v2.0/get_request_token",
                             :authorize_path=>"/authorize")

if config["access_token"].nil?
  request_token = consumer.get_request_token

  puts "\n\n\n\n\n"
  puts "Please go to this url to authorize the script"
  puts request_token.authorize_url
  puts "\n\n\n\n\n"

  oauth_verifier=""

  server = WEBrick::HTTPServer.new(:Port => 8080, :DocumentRoot=>"~",
                                   :BindAddress=>"127.0.0.1")
  server.mount_proc '/callback' do |req,res|
    oauth_verifier= /oauth_verifier=(.*)&?/.match(req.request_uri.to_s)[1]
    res.body="Got your account! Head back to your terminal"
    server.shutdown
  end
  trap 'INT' do server.shutdown end  
  server.start

  access_token = request_token.get_access_token(:oauth_verifier => oauth_verifier)
  config["access_token"] = {"token"=>access_token.token, "secret"=>access_token.secret}
  File.open(CONFIG_LOCATION, 'w+') {|f| f.write(config.to_yaml) }
else
  access_token = OAuth::AccessToken.new(consumer,
                                        config["access_token"]["token"],
                                        config["access_token"]["secret"])
end
config["groups"].each do |group_id|

emails={}
  group_url="https://secure.splitwise.com/api/v2.1/get_group/#{group_id}"
  group = JSON.parse(access_token.get(group_url).body)["group"]
  group["suggested_repayments"].each do |repayment|
    from = get_user(repayment["from"],group["members"])
    to = get_user(repayment["to"],group["members"])
    if emails[to["email"]].nil?
      emails[to["email"]]="Hello!\n"
      emails[to["email"]]+="Let's settle up the #{group["name"]} splitwise group.
Here are the people you need to charge\n\n"
    end
    emails[to["email"]]+="#{from["first_name"]} owes you $#{repayment["amount"]}\n"
    note = CGI.escape("Settling up #{group["name"]}")
    venmo_url="https://venmo.com?txn=charge&recipients=#{from["email"]}&note=#{note}&amount=#{repayment["amount"]}"
    emails[to["email"]]+="#{venmo_url}\n\n"
  end
  puts emails
  emails.each_pair do |email,message|
   send_email(config["smtp_config"], config["smtp_config"]["from_email"],email, message)
  end
end
