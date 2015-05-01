require 'nokogiri'
require 'awesome_print'
require 'net/http'

class MapGenerator

  @@default_config = {
     maps_directory: "../maps",
     euro_map_ccsid: nil
  }

  class HTMLParserError < StandardError ; end
  class MapAlreadyExistsError < StandardError ; end

  def initialize(url,config)
    config = @@default_config.merge(config)
    @maps_directory = config[:maps_directory].chars
    @maps_directory.unshift "/" unless @maps_directory[0] == "/"
    @maps_directory.push "/" unless @maps_directory[-1] == "/"
    @maps_directory = @maps_directory.join

    @config = config

    @xml = Nokogiri::HTML Net::HTTP.get(URI(url))
  end

  def generate!
    selector = "table.wikitable.chset.nounderlines"
    tables = @xml.css(selector)

    map_result = if tables.size == 2 then
      parse_small_table(tables[1])
    elsif tables.size == 1 then
      parse_big_table(tables[0])
    else
      raise HTMLParserError, "No usable input Tables found with : '#{selector}'"
    end      

    output = map_result.ai.lines.to_a
    output[0] = "char_maps[\"IBM-%04i\"] = {\n"%[@ccsid]

    out_name = File.dirname(__FILE__) + @maps_directory + "ibm-%04i.map"%[@ccsid]
    #raise MapAlreadyExistsError,"Map #{out_name} already exists" if File.exists?(out_name)

    File.write out_name,output.join

    if @config[:euro_map_ccsid] then
      output = generate_euro_map(map_result).ai.lines.to_a
      out_name = File.dirname(__FILE__) + @maps_directory + "ibm-%04i.map"%[@config[:euro_map_ccsid]]
      File.write out_name, output.join
    end
  end

  def generate_euro_map(non_euro_map)
    euro_map = non_euro_map.dup
    euro_map["9F".to_i(16)] = "\u20AC" # € zeichen
    euro_map
  end

  def parse_small_table(table)
    @ccsid = @xml.css("table.wikitable.chset.nounderlines > caption").text[/\d+/].to_i
    
    rows = table.css "tr"
    rows.shift # caption
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
    map_result    
  end

  def parse_big_table(table)
    @ccsid = @xml.css('#firstHeading').text[/\d+/].to_i

    rows = table.css 'tr'
    rows.shift # Table header
    rows.pop # footer

    map_result = {}
    count_first = 0
    count_sec   = 0
    rows.each do |row|
      count_sec = 0
      children = row.css 'td'
      children.each do |child|
        hex = count_first.to_s(16) + count_sec.to_s(16)
        value = child.text.lines
        value = value[1].chomp
        value = (value[/[\dABCDEF]{4}/] ? value : '0000')
        map_result[hex.to_i(16)] = eval('"\u' + value + '"')
        count_sec += 1
      end
      count_first += 1
    end
    map_result     
  end

end
