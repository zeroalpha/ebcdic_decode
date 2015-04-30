require 'pry'
require 'slop'

class EBCDICConverter

  class RecordFormatError < StandardError ; end

  def initialize
    @char_maps = {}
    @opts = {}
    @in_file = ""
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

  def read_file(file_name = @opts[:file])
    print "Reading Input file #{file_name} ... "
    @in_file = File.binread file_name
    puts "Done."
  end

  def load_maps
    # Yes i understand, that this is dangerous
    # Ruby itself was just the first format, which describes the map in a human readable format
    # YAML just breaks everything and Marshal isn't "human readable/editable"
    char_maps = {}
    print "Loading Character Maps ... "
    Dir.glob("maps/*").each{|f| eval(File.read(f))}
    puts "Done. (#{char_maps.keys.size} loaded)"
    @char_maps = char_maps
  end

  def convert
    unless @char_maps[@opts[:ccsid]]
      puts "Character Set not found : #{@opts[:ccsid]}"
      exit 1
    end

    case @opts[:recfm].upcase
    when 'FB' then
      convert_fb
    when 'VB' then
      convert_vb
    else
      raise EBCDICConverter::RecordFormatError, "Unsupported Record Format : #{@opts[:recfm]}"
    end
  end

  def convert_fb
    byte_converted = @in_file.bytes.map{|b| @char_maps[@opts[:ccsid]][b]}.join
    @out_file = byte_converted.chars.each_slice(@opts[:lrecl]).to_a.map{|line| line.join}.join("\n")
  end

  def convert_vb
    bytes = @in_file.bytes
    while bytes.size > 0
      #binding.pry
      line_size = bytes[1] # Bytes 0..4 are the RDW. RDW[0..1] holds teh record length and RDW[2..3] are OS reserved (and usually 0)
      line = bytes.slice!(0,line_size)
      line.slice!(0,4) # Discard the RDW 
      @out_file << line.map{|b| @char_maps[@opts[:ccsid]][b]}.join + "\n"
    end
    @out_file
  end

  def write_file(file_name = @opts[:new_name])
    File.write file_name,@out_file
  end

end

conv = EBCDICConverter.new
conv.parse_options(ARGV)
conv.load_maps
conv.read_file
conv.convert
conv.write_file("test.test")