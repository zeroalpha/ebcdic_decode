require 'pry'
require 'slop'

$LOAD_PATH.unshift(File.dirname(__FILE__) + "/lib")
require  'ebcdic_converter'
require 'map_generator'

class MissingRequiredOption < Slop::Error ; end

opts = Slop.new(strict: true, help: true) do 
  banner "Usage : ebcdic_decode.rb [options]"
  separator ""
  separator "Required Option : "
  on '-f','--file','The name of the File to decode', argument: true # ,required: true
  separator "OR"
  on "-I", '--install','create a new charmap from a wikipedia page, takes the URL', argument: true
  separator ""
  separator "Further Options : "
  on '-o','--output','The file name to write the decoded file to', argument: true
  on '-c','--ccsid','The character set used by the input file', default: "0037", argument: true
  on '-r','--recfm','The record format of the input Dataset',argument: true, default: "FB"
  on '-l','--lrecl','The record length in case of a Fixed LRECL Dataset',as: Integer, argument: true
end

begin
  opts.parse
  raise MissingRequiredOption, "You need to specify -f or -I" unless opts[:file] || opts[:install]
rescue Slop::Error => e
  puts e.message
  puts opts
  exit 1
end

opts = opts.to_hash

if file = opts[:file] then
  EBCDICConverter.new(file,opts).convert!
elsif url = opts[:install]
  MapGenerator.new(url).generate!
end

