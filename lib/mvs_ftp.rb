require 'net/ftp'
require 'pry'

class MvsFtp
  
  def initialize(host,login)
    begin
      @ftp = Net::FTP.new
      @ftp.connect host,21
    rescue => e
      puts "\nFailed to connect to #{host}:21.\nReason: #{e.inspect}"
      exit 1
    end
    raise LoginFailedError, "Login rejected for user #{login[0]}" unless @ftp.login(*login)    
    @ftp.sendcmd 'SITE RDW' # Enable transfer of RDW for VB Datasets
  end

  def download(dataset)
    #local_file = File.join(File.dirname(__FILE__),'..','downloads',dataset)
    #"550 Retrieval of a whole partitioned data set is not supported. Use MGET or MVSGET for this purpose.\n"
    #binding.pry
    puts "Downloading #{dataset}"
    ret = nil
    begin
      ret = {name: dataset, member: [{name: dataset, data: @ftp.getbinaryfile(dataset,nil)}]}
    rescue => e
      #File.delete local_file
      if(e.message.index("550")) then
        ret = download_member(dataset)
      else
        raise e
      end
    end
    ret
  end

  def download_member(partitioned_dataset)
    @ftp.chdir "'#{partitioned_dataset}'"
    member = @ftp.dir
    member.shift #header zeile entfernen
    member.map!{|line| line.split(" ")[0]} #den wahnsinn vom FTP auf den member namen eindampfen
    member.map! do |mem|
      puts "Downloading #{partitioned_dataset}(#{mem})"
      {name: mem, data: @ftp.getbinaryfile(mem,nil)}
    end
    #binding.pry
    {name: partitioned_dataset, member: member}
  end
end