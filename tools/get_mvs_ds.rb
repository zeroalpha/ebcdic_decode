require 'slop'
require_relative '../lib/mvs_ftp.rb'

require 'pry'

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

unless pw = opts[:password]
  print "Please Enter your password for #{opts[:user]}:"
  pw = STDIN.noecho(&:gets).chomp
  puts ""
end
login = [opts[:user],pw]

class LoginFailedError < StandardError ; end

ftp = MvsFtp.new host,login

ftp.download dataset