require File.dirname(__FILE__) + '/../lib/ebcdic_converter.rb'

require 'fileutils'

describe EBCDICConverter do

  before :all do
    @input_filename = File.dirname(__FILE__) + '/assets/EBCDIC.TESTDATA.RECV'
    @input_file = File.binread(@input_filename)
    @unicode_sample_data = File.binread(File.dirname(__FILE__) + '/assets/test_data_recfm_vb_unicode.txt').unpack('U*').pack('U*') #this is just stupid
  end


  describe '#initialize' do
    before :all do
      @loaded_map = YAML.load File.read(File.dirname(__FILE__) + '/../maps/ibm-1141.yml')
      @conv = EBCDICConverter.new @input_filename, ccsid: "ibm-1141", recfm: 'vb'
    end

    context 'with a filename' do
      it 'creates a new instance of the class' do
        expect(EBCDICConverter.new @input_filename).to be_a(EBCDICConverter)
      end

      it 'sets the default config' do
        default = {
          recfm: 'FB',
          lrecl: 80,
          ccsid: 'IBM-0037',
          maps_directory: "/../maps/"
        }
        expect(EBCDICConverter.new(@input_filename).instance_variable_get('@config')).to eq(default)
      end   
    end

    context 'with filename and specific config' do
      it 'creates a new instance of the class' do
        expect(@conv).to be_a(EBCDICConverter)
      end

      it 'normalizes the config parameter' do
        expect(@conv.instance_variable_get('@config')).to eq({
          ccsid: "IBM-1141", recfm: 'VB', maps_directory: '/../maps/', lrecl: 80 #LRECL is set to the default
          })
      end
    end

    context 'without a filename' do
      it 'raises a missing argument exception' do
        expect { EBCDICConverter.new }.to raise_error ArgumentError
      end
    end

    it 'loads the character set for the given ccsid' do
      expect(@conv.instance_variable_get('@map')).to eq(@loaded_map)
    end

    it 'reads the input file in binary mode' do
      expect(@conv.instance_variable_get('@in_file')).to eq(@input_file)
    end
  end

  describe '#convert!' do

    after :all do
      Dir.glob(File.dirname(__FILE__) + '/assets/*-decoded-IBM-*.txt').each{|f| File.delete(f)}
    end

    before :each do #convert! alters state, so we need to create a new EBCDICConverter instance for every test
      @conv = EBCDICConverter.new @input_filename,ccsid: "ibm-1141", recfm: 'vb'
    end
    
    it 'raises an RecordFormatError if recfm is not covered' do
      conv = EBCDICConverter.new @input_filename,ccsid: "ibm-1141", recfm: 'superB'
      expect{ conv.convert! }.to raise_error(EBCDICConverter::RecordFormatError)
    end

    context 'creates a new file' do

      before :all do
        @conv = EBCDICConverter.new @input_filename,ccsid: "ibm-1141", recfm: 'vb'
        @conv.convert!
        @converted_filename = @input_filename + '-decoded-IBM-1141-VB.txt'
      end

      it 'with \'-decoded-IBM-<CCSID>-<RECFM>.txt\' appended' do
        expect(File).to exist(@converted_filename)
      end

      it 'which contents match the Unicode sample data' do
        result_data = File.binread(@converted_filename).unpack("U*").pack("U*")
        expect(result_data).to eq(@unicode_sample_data)
      end
    end
  end

  describe '#convert_vb(input)' do
    before :each do
      @conv = EBCDICConverter.new @input_filename,ccsid: "ibm-1141", recfm: 'vb'
    end

    it 'returns the contents of input converted to Unicode' do
      
      expect(@conv.convert_vb(@input_file)).to eq(@unicode_sample_data)
    end
  end
end