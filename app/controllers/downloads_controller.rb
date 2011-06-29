class DownloadsController < ApplicationController
  CHROMOSOMES = %w{1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y}
  FILE_PATH = File.join(RAILS_ROOT, "public/files")
  FILE_NAME = 'oligo_design_v18_chr#.txt.gz'
  
  def index
    @chromosomes = CHROMOSOMES
  end
  
  #*******************************************************************************************#
  # Download zip file                                                                         #
  #*******************************************************************************************#
  def zip_download
    params[:chr_num] ||= 'X'
    file_name = FILE_NAME.gsub(/#/, params[:chr_num].to_s)
    filepath = File.join(FILE_PATH, file_name)
#
    if FileTest.file?(filepath)
      flash.now[:notice] = "Zip file for chromosome " + params[:chr_num] + " successfully downloaded"
      send_file(filepath, :disposition => 'attachment')
    else
      flash[:notice] = "Error downloading zip file for chromosome " + params[:chr_num] + " - file not found"
      #flash[:notice] = "Error downloading zip file for " + filepath + " - file not found"
      redirect_to :action => :index
    end
  end
  
end
