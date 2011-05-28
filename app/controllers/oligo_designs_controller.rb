class OligoDesignsController < ApplicationController
  skip_before_filter :login_required, :only => :welcome
#
  def welcome
  end
  
  # GET /oligo_designs
  def index
    @oligo_designs = OligoDesign.curr_ver.find(:all)
  end
  #
  # GET /oligo_designs/1
  def show
    @oligo_design = OligoDesign.find(params[:id], :include => :oligo_annotation )
    @comments     = @oligo_design.comments.sort_by(&:created_at).reverse
  end

  #*******************************************************************************************#
  # Method for adding comment associated with a specific oligo                                #
  #*******************************************************************************************#
  def add_comment
    unless params[:comment].nil? || params[:comment]== ''
      @oligo_design = OligoDesign.find(params[:id])
      store_comment(@oligo_design, params)
    end

    redirect_to :action => 'show', :id => params[:id]
  end

end