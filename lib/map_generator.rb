require 'nokogiri'
require 'awesome_print'
require 'pry'


# This tool reads a File with a Code page translation table from wikipedia (http://en.wikipedia.org/wiki/EBCDIC_273)
# And creates a Character map
xml = Nokogiri::XML File.read("test.html")

rows = xml.css "tr"
set_name = rows.shift.children.select{|c| c.type == 1}[0].child.text.split("→")[0].chop # Tabellenüberschrift
set_id = set_name.split(" ")[1].to_i
rows.shift # Table Header

map_result = {}

count_first = 0
count_sec   = 0
rows.each do |row|
	count_sec = 0
	children = row.children.select{|c| c.type == 1} #XML::Element (3 would be XML::Text)
	children.each do |child|
		next if child.children.text.index("_")
		hex = count_first.to_s(16) + count_sec.to_s(16)
		value = '"\u00' + child.children.text + '"'
#		puts value
		map_result[hex.to_i(16)] = eval(value)
		count_sec += 1
	end
	count_first += 1
end

#binding.pry

map_result = map_result.ai

map_result = "char_maps[\"IBM-%04i\"] = \\\n"%[set_id]  + map_result

File.write "#{set_id}.map",map_result

puts ""