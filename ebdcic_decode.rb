require 'pry'
require 'base64'
require File.dirname(__FILE__) + '/lib/ebcdic_converter.rb'
require File.dirname(__FILE__) + '/lib/mvs_ftp.rb'

puts("Please provide a Dataset to convert")&&exit(1) unless ARGV[0]
dataset = ARGV[0]
puts dataset

ftp = MvsFtp.new "mvs4.rzffm.db.de",['zcm0800',Base64.decode64("T21lZ2EzMDM=\n")]

data = ftp.download(dataset)

puts "Converting #{dataset}"
conv = EbcdicConverter.new

ret = data[:member].map do |ds|
  puts "Converting #{dataset}(#{ds[:name]})"
  #binding.pry
  {
    name: ds[:name],
    data: conv.convert(ds[:data],500,dataset_config = {})
  }
end

ret = {
  name: data[:name],
  member: ret
}

ret[:member].each do |ds|
  filename = File.dirname(__FILE__) + '/downloads/' + ret[:name] + '/' + ds[:name]
  File.write filename,ds[:data]
end

binding.pry

puts ""