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

  def parse_options(items)

    opts = Slop.new(strict: true, help: true) do 
      banner "Usage : ebcdic_decode.rb [options]"
      separator ""
      separator "Required Option : "
      on '-f','--file','The name of the File to decode',required: true, argument: true
      separator ""
      separator "Further Options : "
      on '-o','--output','The file name to write the decoded file to', argument: true
      on '-c','--ccsid','The character set used by the input file', default: "0037", argument: true
      on '-r','--recfm','The record format of the input Dataset',argument: true, default: "FB"
      on '-l','--lrecl','The record length in case of a Fixed LRECL Dataset',as: Integer, argument: true
    end

    begin
      opts.parse
    rescue Slop::Error => e
      puts e.message
      puts opts
      exit 1
    end

    opts = opts.to_hash

    if opts[:ccsid][/^\d+$/] then
      opts[:ccsid] = "IBM-" + "%04i"%[opts[:ccsid].to_i]  # Prepend IBM- to the map string, if it consists solely of Digits
    end

    opts[:new_name] = opts[:output] ? opts[:output] : opts[:file] + '_decoded_' + opts[:ccsid]
    @opts = opts
  end

  def read_file
    File.binread @file_name
  end

  def load_maps(maps_directory)
    # Yes i understand, that this is dangerous
    # Ruby itself was just the first format, which describes the map in a human readable format
    # YAML just breaks everything and Marshal isn't "human readable/editable"
    char_maps = {}
    Dir.glob(File.dirname(__FILE__) + maps_directory + "*").each{|f| eval(File.read(f))}
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
    byte_converted = @in_file.bytes.map{|b| @map[b]}.join
    @out_file = byte_converted.chars.each_slice(@config[:lrecl]).to_a.map{|line| line.join}.join("\n")
  end

  def convert_vb
    bytes = @in_file.bytes
    while bytes.size > 0
      #binding.pry
      line_size = bytes[1] # Bytes 0..4 are the RDW. RDW[0..1] holds teh record length and RDW[2..3] are OS reserved (and usually 0)
      line = bytes.slice!(0,line_size)
      line.slice!(0,4) # Discard the RDW 
      @out_file << line.map{|b| @map[b]}.join + "\n"
    end
    @out_file
  end

  def write_file(file_name = nil)
    file_name = file_name ? file_name : "#{@file_name}-decoded-#{@config[:ccsid]}-#{@config[:recfm]}.txt"    
    File.write file_name,@out_file
  end
end