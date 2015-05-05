require 'yaml'

class EBCDICConverter

  class RecordFormatError < StandardError ; end

  DEFAULT_CONFIG = {
    recfm: 'FB',
    lrecl: 80,
    ccsid: 37,
    maps_directory: "../maps"
  }

  def initialize(file_name,config = {})
    @config = DEFAULT_CONFIG.merge(config)

    @config[:ccsid] = "IBM-%04i"%[@config[:ccsid].to_s[/\d+/].to_i]
    
    tmp = @config[:maps_directory].chars
    tmp.unshift "/" unless tmp[0] == "/"
    tmp.push "/" unless tmp[-1] == "/"
    @config[:maps_directory] = tmp.join

    #@char_maps = load_maps(@config[:maps_directory])
    #@map = @char_maps[@config[:ccsid]]
    @map = load_map @config[:ccsid]
    @config[:recfm] = @config[:recfm].upcase

    @file_name = file_name
    @in_file = File.binread @file_name
  end

  def load_maps(maps_directory)
    char_maps = {}
    Dir.glob(File.dirname(__FILE__) + maps_directory + "*.yml").each{|f| char_maps[f[/ibm-\d{4}/].upcase] = YAML.load(File.read(f))}
    char_maps
  end

  def load_map(ccsid)
    begin
      char_map = YAML.load(File.read([File.dirname(__FILE__),@config[:maps_directory],ccsid.downcase,'.yml'].join))
    rescue => e
      puts e.inspect
      abort
    end
  end

  def convert!
    converted = case @config[:recfm]
    when 'FB' then
      convert_fb(@in_file)
    when 'VB' then
      convert_vb(@in_file)
    else
      raise EBCDICConverter::RecordFormatError, "Unsupported Record Format : #{@config[:recfm]}"
    end

    write_file converted
  end

  def convert_fb(input)
    input.bytes.map{|b| @map[b]}.each_slice(@config[:lrecl]).to_a.map{|line| line.pack('U*')}.join("\n")
  end

  def convert_vb(input)
    bytes = input.bytes
    ret = ""
    while bytes.size > 0
      #FIXME Add dualbyte lengths
      line_size = bytes[1] # Bytes 0..4 are the RDW. RDW[0..1] holds the record length and RDW[2..3] are OS reserved (and usually 0)
      line = bytes.slice!(0,line_size)
      line.slice!(0,4) # Discard the RDW 
      ret << line.map{|b| @map[b]}.pack("U*") + "\n"
    end
    ret.chomp! # delete the trailing newline
    ret
  end

  def write_file(data,file_name = nil)
    file_name = file_name ? file_name : "#{@file_name}-decoded-#{@config[:ccsid]}-#{@config[:recfm]}.txt"    
    File.binwrite file_name,data
  end
end