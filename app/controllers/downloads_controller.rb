class DownloadsController < ApplicationController
  FILE_PATH = File.join(RAILS_ROOT, "public/files")
  CHROMOSOMES = %w{1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y}
  
  def index
    @chromosomes = CHROMOSOMES
  end
  
  #*******************************************************************************************#
  # Download zip file                                                                         #
  #*******************************************************************************************#
  def zip_save
    params[:chr_num] ||= 1
    #file_name = 'oligo_design_v18_inf_flank_c_1000_24KmerMask_thresh1.0.chr1.reformatted.txt.gz'
    #file_name.gsub!(/@/, params[:chr_num].to_s)
    file_name = 'Selector_Stats_06072011.txt'
    filepath = File.join(FILE_PATH, file_name)

    if FileTest.file?(filepath)
      flash[:notice] = "Zip file #{filepath} successfully downloaded"
      #send_file(filepath, :disposition => "attachment")
      redirect_to :action => :index
    else
      #flash[:notice] = "Error downloading zip file for " + params[:chr_num] + " - file not found"
      flash[:notice] = "Error downloading zip file for " + filepath + " - file not found"
      redirect_to :action => :index
    end
  end
  
end
