require 'pry'
require 'slop'

opts = Slop.new(strict: true, help: true) do 
	banner "Usage : ebcdic_decode.rb [options]"
	separator ""
	separator "Required Option : "
	on '-f','--file','The name of the File to decode',required: true, argument: true
	separator ""
	separator "Further Options : "
	on '-o','--output','The file name to write the decoded file to', argument: true
	on '-c','--ccsid','The character set used by the input file', default: "0037", argument: true
	on '-l','--lrecl','The record length in case of a Fixed LRECL Dataset',as: Integer, argument: true
end

begin
	opts.parse
rescue Slop::Error => e
	puts e.message
	puts opts
	exit 1
end
puts opts.to_hash

opts = opts.to_hash

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

# In this case the File is most likely fixed blocked
if record_length = opts[:lrecl] then
	print "Folding lines (LRECL: #{record_length}) ... "
	file = file.chars.each_slice(record_length).to_a.map{|line| line.join}.join("\n")
	puts "Done."
end


print "Writing file to #{new_name} ... "
File.write new_name , file
puts "Done."