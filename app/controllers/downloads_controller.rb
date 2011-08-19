class DownloadsController < ApplicationController
  COORDS_FILE = 'oligo_design_v18_chr#.' + (CAPISTRANO_DEPLOY ? 'coordinates.gff.zip' : 'txt.gz')
  ANNOT_FILE  = 'oligo_design_v18_chr#.annotations.zip'
  
  def index
    @chromosomes = OligoDesign::CHROMOSOMES
  end
  
  #*******************************************************************************************#
  # Download zip file                                                                         #
  #*******************************************************************************************#
  def zip_download
    params[:chr_num] ||= 'X'
    params[:file_type] ||= 'Coord'
    
    file_name = (params[:file_type] == 'Annot' ? ANNOT_FILE : COORDS_FILE).gsub(/#/, params[:chr_num].to_s)
    filepath = File.join(ZIP_ABS_PATH, file_name)
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
