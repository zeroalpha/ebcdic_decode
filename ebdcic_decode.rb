#require 'pry'
require 'slop'


opts = Slop::Options.new
opts.banner = "Usage : ebcdic_decode.rb [options]"
opts.separator ""
opts.separator "Required Option : "
opts.string '-f','--file','-i','--input','The name of the File to decode',required: true
opts.separator ""
opts.separator "Further Options : "
opts.string '-o','--output','The file name to write the decoded file to'
opts.string '-c','--ccsid','--character-set','The character set used by the input file', default: "0037"

opt_parser = Slop::Parser.new(opts)

opts = opt_parser.parse(ARGV)

unless opts[:file]
	puts "File is a required Option"
	puts opts
	exit 1
end

#file_name  = ARGV[0]
#map = ARGV[1]

if opts[:ccsid][/^\d+$/] then
	opts[:ccsid] = "IBM-" + "%04i"%[opts[:ccsid].to_i] 	# Prepend IBM- to the map string, if it consists solely of Digits
end

file_name = opts[:file]
map = opts[:ccsid]

new_name = opts[:output] ? opts[:output] : file_name + '_decoded_' + map

print "Reading Input file #{file_name} ... "
file = File.binread file_name
puts "Done."

char_maps = {}

# Yes i understand, that this is dangerous
# Ruby itself was just the first format, which describes the map in a human readable format
# YAML just breaks everything and Marshal isn't "human readable/editable"

print "Loading Character Maps ... "
Dir.glob("maps/*").each{|f| eval(File.read(f))}
puts "Done. (#{char_maps.keys.size} loaded)"

unless char_maps[map]
	puts "Character Set not found : #{map}"
	exit 1
end

print "Mapping Input bytes to Unicode Codepoints ... "
file = file.bytes.map{|b| char_maps[map][b]}.join("")
puts "Done."
print "Writing file to #{new_name} ... "
File.write new_name , file
puts "Done."