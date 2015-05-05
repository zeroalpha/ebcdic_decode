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
rescue => e
  puts "\nFailed to connect to #{host}:#{opts[:port]}.\nReason: #{e.inspect}"
  exit 1
end
raise LoginFailedError, "Login rejected for user #{login[0]}" unless ftp.login(*login)

puts "Done."

# Enable transfer of RDW for VB Datasets
ftp.sendcmd 'SITE RDW'

print "Recieving DS: #{dataset} ... "
#ftp.binary = true
ftp.getbinaryfile dataset
puts "Done."
