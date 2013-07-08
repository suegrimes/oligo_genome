class OligoDesignsController < ApplicationController
  #skip_before_filter :login_required, :only => :welcome

  def welcome
  end
  
  # GET /oligo_designs
  def index
    #@oligo_designs = OligoDesign.curr_ver.find(:all)
    @oligo_designs = OligoDesign.curr_ver.all
  end
  #
  # GET /oligo_designs/1
  def show
    @oligo_design = OligoDesign.find(params[:id], :include => :oligo_annotation )
  end

end