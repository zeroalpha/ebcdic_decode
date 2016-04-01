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

  def download(dataset,local_file=nil)
    local_file = File.join(File.dirname(__FILE__),'..','downloads',dataset)
    #"550 Retrieval of a whole partitioned data set is not supported. Use MGET or MVSGET for this purpose.\n"
    #binding.pry
    ret = nil
    begin
      ret = @ftp.getbinaryfile(dataset,local_file)
    rescue => e
      File.delete local_file
      if(e.message.index("550")) then
        ret = download_member(dataset,local_file)
      else
        puts e.inspect
        ret = nil
      end
    end
    ret
  end

  def download_member(partitioned_dataset,local_dir)
    FileUtils.mkdir_p(local_dir) unless Dir.exists?(local_dir)
    @ftp.chdir "'#{partitioned_dataset}'"
    member = @ftp.dir
    member.shift #header zeile entfernen
    member.map!{|line| line.split(" ")[0]} #den wahnsinn vom FTP auf den member namen eindampfen
    member.map do |mem|
      local_path = File.join(local_dir,mem)
      puts local_path 
      @ftp.getbinaryfile(mem,local_path)
    end
    binding.pry
  end
end