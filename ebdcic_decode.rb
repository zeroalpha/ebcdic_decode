require 'pry'
require 'yaml'
require File.dirname(__FILE__) + '/lib/ebcdic_converter.rb'
require File.dirname(__FILE__) + '/lib/mvs_ftp.rb'

unless ARGV[0]
  puts("Please provide a Dataset to convert")
  exit 1
end
dataset = ARGV[0]

ccsid = 500
if ARGV[1]
  ccsid = ARGV[1].to_i
end

secret = YAML.load(File.read(File.dirname(__FILE__) + '/config/secret.yml'))
ftp = MvsFtp.new "mvs4.rzffm.db.de",[secret[:user],secret[:password]]

data = ftp.download(dataset)

puts "Converting #{dataset}"
conv = EbcdicConverter.new

ret = data[:member].map do |ds|
  puts "Converting #{dataset}(#{ds[:name]})"
  #binding.pry
  {
    name: ds[:name],
    data: conv.convert(ds[:data],ccsid,dataset_config = {})
  }
end

ret = {
  name: data[:name],
  member: ret
}

ret[:member].each do |ds|
  filename = File.dirname(__FILE__) + '/downloads/' + ret[:name] + '/' + ds[:name]
  puts "Saving #{filename}"
  Dir.mkdir(File.dirname(filename)) unless Dir.exist?(File.dirname(filename))
  File.write filename,ds[:data]
end

#binding.pry

puts ""