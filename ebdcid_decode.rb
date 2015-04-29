#require 'pry'
#require 'yaml'

file_name  = ARGV[0]

map = ARGV[1]

map = "IBM-0037" unless map 				# Default to IBM-US

if map[/^\d+$/] then
	map = "IBM-" + "%04i"%[map.to_i] 	# Prepend IBM- to the map string, if it consists solely of Digits
end

new_name = file_name + '_decoded_' + map

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