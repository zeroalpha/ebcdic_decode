require File.dirname(__FILE__) + '/../lib/ebcdic_converter.rb'

describe EBCDICConverter do
  describe "#initialize" do

    before :all do
      @filename = File.dirname(__FILE__) + '/assets/EBCDIC.TESTDATA.RECV'
      @conv = EBCDICConverter.new @filename, ccsid: "ibm-1141", recfm: 'vb'
    end

    context 'with a filename' do
      it 'creates a new instance of the class' do
        expect(EBCDICConverter.new @filename).to be_a(EBCDICConverter)
      end

      it 'sets the default config' do
        default = {
          recfm: 'FB',
          lrecl: 80,
          ccsid: 'IBM-0037',
          maps_directory: "/../maps/"
        }
        expect(EBCDICConverter.new(@filename).instance_variable_get('@config')).to eq(default)
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

    it 'loads the character set for the given ccsid'

  end
end