require 'net/ftp'
require 'slop'

opts = Slop.new(strict: true, help: true) do 
  banner "Usage : get_zos_dataset [options] HOST DATASET"
  separator ""
  separator "Required Option : "
  on '-u','--user','The User ID used to connect to the HOST',required: true, argument: true
  separator ""
  separator "Further Options : "
  on '-p','--password',"The password used to connect to HOST.\nIn case no password is supplied, it will be asked for during connect", argument: true
  on '-P','--port', 'The port used to connect to HOST. Defaults to 21',default: 21, as: Integer, argument: true
end

begin
  opts.parse!
rescue Slop::Error => e
  puts e.message
  puts opts
  exit 1
end

host, dataset = ARGV
dataset = "'#{dataset}'" unless dataset[0] == "'"

unless pw = opts[:password]
  print "Please Enter your password for #{opts[:user]}:"
  pw = STDIN.noecho(&:gets).chomp
  puts ""
end
login = [opts[:user],pw]

class LoginFailedError < StandardError ; end

print "Connecting to #{host}:#{opts[:port]} ... "
begin
  ftp = Net::FTP.new
  ftp.connect host,opts[:port]
  raise LoginFailedError unless ftp.login(*login)
rescue => e
  puts "\nFailed to connect to #{host}:#{opts[:port]}.\nReason: #{e.inspect}"
  exit 1
end
puts "Done."

# Enable transfer of RDW for VB Datasets
ftp.sendcmd 'SITE RDW'

print "Recieving DS: #{dataset} ... "
#ftp.binary = true
ftp.getbinaryfile dataset
puts "Done."

#host = "172.21.87.134" #FFM4
#login = ["dbft064","pdbft064"]
#remote_dir = "AGMV800.GLOBAL.WOM.DATA"
#local_dir = Rails.root.join('tmp','import','wstat','ftp').to_s

#print "Connecting to #{host} ..."
#begin/rescue/end ist Rubys Exception Handling, wenn zwischen begin und rescue eine Exception auftritt
#wird sie der Variable e zugewiesen und der rescue block ausgeführt
#begin
#  ftp = Net::FTP.new host # FTP Verbindung aufbauen
#  login_check = ftp.login(*login) # Mit user und PW anmelden (siehe Ruby Splat Operator für den stern)
#rescue => e
#  UpdateStatus.create! task: "Update", item: "FTP Connection", time: Time.now, status: "Could not open FTP Connection to #{host}\nReason: #{e.inspect}"
#  puts "\nCould not open FTP Connection to #{host}\nReason: #{e.inspect}"
#  exit 1 # Wenn wir nicht zum FTP Connecten können beenden wir den Rake task
#end
