class DownloadsController < ApplicationController
  FILE_PATH = File.join(RAILS_ROOT, "public/files")
  CHROMOSOMES = %w{1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y}
  
  def index
    @chromosomes = CHROMOSOMES
  end
  
  #*******************************************************************************************#
  # Download zip file                                                                         #
  #*******************************************************************************************#
  def download_zip_file
    filepath = File.join(FILE_PATH, params[:zip_file] + '.zip')

    if FileTest.file?(filepath)
      flash[:notice] = "Zip file successfully downloaded"
      send_file(filepath, :disposition => "attachment")
      redirect_to :action => :index
    else
      #flash[:notice] = "Error downloading zip file for " + params[:zip_file] + " - file not found"
      flash[:notice] = "Error downloading zip file for " + filepath + " - file not found"
      redirect_to :action => :index
    end
  end
  
end
