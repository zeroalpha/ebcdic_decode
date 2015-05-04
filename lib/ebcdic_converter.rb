require 'yaml'

class EBCDICConverter

  class RecordFormatError < StandardError ; end

  @@default_config = {
    recfm: 'FB',
    lrecl: 80,
    ccsid: 37,
    maps_directory: "../maps"
  }

  def initialize(file_name,config = {})
    @config = @@default_config.merge(config)
    
    @config[:ccsid] = "IBM-%04i"%[config[:ccsid][/\d+/].to_i]
    
    tmp = @config[:maps_directory].chars
    tmp.unshift "/" unless tmp[0] == "/"
    tmp.push "/" unless tmp[-1] == "/"
    @config[:maps_directory] = tmp.join

    @char_maps = load_maps(@config[:maps_directory])
    @map = @char_maps[@config[:ccsid]]
    @config[:recfm] = @config[:recfm].upcase

    @file_name = file_name
    @in_file = read_file
    @out_file = ""
  end

  def read_file
    File.binread @file_name
  end

  def load_maps(maps_directory)
    char_maps = {}
    Dir.glob(File.dirname(__FILE__) + maps_directory + "*.yml").each{|f| char_maps[f[/ibm-\d{4}/].upcase] = YAML.load(File.read(f))}
    char_maps
  end

  def convert!
    unless @char_maps[@config[:ccsid]]
      puts "Character Set not found : #{@config[:ccsid]}"
      exit 1
    end

    case @config[:recfm]
    when 'FB' then
      convert_fb
    when 'VB' then
      convert_vb
    else
      raise EBCDICConverter::RecordFormatError, "Unsupported Record Format : #{@opts[:recfm]}"
    end

    write_file
  end

  def convert_fb
    converted_bytes = @in_file.bytes.map{|b| @map[b]}
    @out_file = converted_bytes.each_slice(@config[:lrecl]).to_a.map{|line| line.pack('U*')}.join("\n")
  end

  def convert_vb
    bytes = @in_file.bytes
    while bytes.size > 0
      #binding.pry
      #FIXME Add dualbyte lengths
      line_size = bytes[1] # Bytes 0..4 are the RDW. RDW[0..1] holds the record length and RDW[2..3] are OS reserved (and usually 0)
      line = bytes.slice!(0,line_size)
      line.slice!(0,4) # Discard the RDW 
      @out_file << line.map{|b| @map[b]}.pack("U*") + "\n"
    end
    @out_file
  end

  def write_file(file_name = nil)
    file_name = file_name ? file_name : "#{@file_name}-decoded-#{@config[:ccsid]}-#{@config[:recfm]}.txt"    
    File.write file_name,@out_file
  end
end