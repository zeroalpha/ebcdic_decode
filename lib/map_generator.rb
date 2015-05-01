require 'nokogiri'
require 'awesome_print'
require 'open-uri'

class MapGenerator

  class MapAlreadyExistsError < StandardError ; end

  def initialize(url, maps_directory = "../maps")
    @xml = Nokogiri::HTML open(url)
    @maps_directory = maps_directory
    @maps_directory.unshift "/" unless @maps_directory[0] == "/"
    @maps_directory.push "/" unless @maps_directory[-1] == "/"
  end

  def generate!
    table = xml.css("table.wikitable.chset.nounderlines")[1] # we want the second "smaller" table
    rows = table.css "tr"

    set_name = xml.css("table.wikitable.chset.nounderlines > caption").text
    set_id = set_name[/\d+/].to_i
    rows.shift # Caption Row
    rows.shift # Table Header


    map_result = {}

    count_first = 0
    count_sec   = 0
    rows.each do |row|
      count_sec = 0
      children = row.css "td"
      children.shift # row header
      children.each do |child|
        hex = count_first.to_s(16) + count_sec.to_s(16)
        value = '"\u00' + child.children.text + '"'
        map_result[hex.to_i(16)] = eval(value)
        count_sec += 1
      end
      count_first += 1
    end

    map_result = map_result.ai.lines.to_a
    map_result[0] = "char_maps[\"IBM-%04i\"] = {\n"%[set_id]

    out_name = File.dirname(__FILE__) + @maps_directory + "ibm-%04i.map"%[set_id]
    raise MapAlreadyExistsError,"Map #{out_name} already exists" if File.exists?(out_name)

    File.write out_name,map_result.join
  end
end
