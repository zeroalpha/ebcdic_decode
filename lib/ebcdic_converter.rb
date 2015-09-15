
class EbcdicConverter
  
  class CharacterMapNotFound < StandardError ; end
  class NonNumericCCSIDError < StandardError ; end
  DEFAULT_CONFIG = {
    recfm: 'FB',
    lrecl: 80,
    ccsid: 37,
    maps_directory: "../maps"
  }

  def convert(input_string,input_charmap,dataset_config = {})
    config = DEFAULT_CONFIG.merge(dataset_config)
    @map = load_map(input_charmap)
    case config['recfm']
    when 'FB'
      convert_fb(input_string,config['lrecl'])
    when 'VB'
      convert_vb(input_string)
    end
  end

  private
  def convert_fb(input,record_length)
    input.bytes.map{|b| @map[b]}.each_slice(record_length).to_a.map{|line| line.pack('U*')}.join("\n")
  end

  def convert_vb(input)
    bytes = input.bytes
    ret = ""
    while bytes.size > 0
      #FIXME Add dualbyte lengths
      line_size = bytes[1] # Bytes 0..4 are the RDW. RDW[0..1] holds the record length and RDW[2..3] are OS reserved (and usually 0)
      line = bytes.slice!(0,line_size)
      line.slice!(0,4) # Discard the RDW
      ret << line.map{|b| @map[b]}.pack("U*") << "\n"
    end
    ret.chomp!
    ret
  end

  def load_map(ccsid)
    if (ccsid = ccsid.to_s[/\d+/].to_i) == 0
      raise NonNumericCCSIDError, "The CCSID needs to be an Integer or a String containing the number"
    end
    ccsid = "IBM-%04i"%[ccsid]
    map_filename = File.dirname(__FILE__) + '../maps' + ccsid.downcase + '.yml'
    begin
      char_map = YAML.load(File.read(map_filename))
    rescue => e
      raise CharacterMapNotFound, "Failed to find the map file #{map_filename}"
    end
  end
end