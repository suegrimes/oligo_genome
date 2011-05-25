class OligoDesignsController < ApplicationController
  skip_before_filter :login_required, :only => :welcome
#
  def welcome
  end
#  
  def export_design
    add_one_to_counter('export')
#
    export_type = 'T1'
    design_ids = params[:export_id]
    @version_id = set_version_id(params[:version_id])
    @oligo_designs = get_oligos_by_id(design_ids, @version_id)
    file_basename  = "oligodesigns_" + Date.today.to_s

    case export_type
      when 'T1'  # Export to tab-delimited text using csv_string
        @filename = file_basename + ".txt"
        csv_string = export_designs_csv(@oligo_designs)
        send_data(csv_string,
          :type => 'text/csv; charset=utf-8; header=present',
          :filename => @filename, :disposition => 'attachment')

      # To export using this method, need a version of export_design.html with tabs, and without any html markup
      when 'T2' # Export to tab-delimited text using export_design_txt.html (currently doesn't exist)
        @filename = file_basename + ".txt"
        headers['Content-Type']="text/x-csv"
        headers['Content-Disposition']="attachment;filename=\"" + @filename + "\""
        headers['Cache-Control'] = '' 
        render :action => :export_design, :layout => false

      when 'E'  # Export to Excel using export_design.html
        @filename = file_basename + ".xls"
        headers['Content-Type']="application/vnd.ms-excel"
        headers['Content-Disposition']="attachment;filename=\"" + @filename + "\""
        headers['Cache-Control'] = ''
        render :action => :export_design, :layout => false
#        render :action => :debug
#
      else # Use for debugging
        csv_string = export_designs_csv(@oligo_designs)
        render :text => csv_string
    end

  end 
  #
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
  # Methods for input of parameters for retrieval of specific oligo designs                   #
  #*******************************************************************************************#
  def select_params
    @genes    = (params[:genes] ? params[:genes] : '')
  end

  #*******************************************************************************************#
  # Method for listing oligo designs, based on parameters entered above                       #
  #*******************************************************************************************#
  def list_selected
    param_type = params[:param_type] ||= 'proj_gene'

    error_found = false
    @version_id = set_version_id(nil)
    @rc = check_params2(params)

    case @rc
      when /e\d/ # error code ('e' followed by digit)
      error_found    = true
      
    when 'g'  #gene list entered
      gene_list      = create_array_from_text_area(params[:genes])
      @oligo_designs = get_oligos_by_gene(nil, gene_list, @version_id) 
      error_found    = check_if_blank(@oligo_designs, 'oligos', 'project/gene(s)')
    end

    if error_found
      redirect_to :action => 'select_params', :genes => params[:genes]
    else
      render :action => 'list_selected'
    end
  end

  #*******************************************************************************************#
  # Method for download of zip file of oligos for entire exonome                              #
  #*******************************************************************************************#
  def zip_download
    add_one_to_counter('zip')
    download_zip_file if request.post?
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


  private

  #*******************************************************************************************#
  # Method for checking parameters from "select_params"                                       #    
  #*******************************************************************************************#
  def check_params2(params, action='list')
    # check first for #nr genes > 400 which can cause browser errors
    nr_genes = params[:genes].split.size if params[:genes]
    if nr_genes && nr_genes > 400
        params[:genes] = ''  #reset params[:genes] to avoid browser errors
        flash[:notice] = "Too many genes (#{nr_genes}) in list - please limit to 400 genes"
        rc = 'e2'

    elsif !params[:genes].blank?
      rc = 'g'

    else
      # error - genes are blank
      flash[:notice] = 'Please select one or more gene(s) for this query'
      rc = 'e1'
    end
    return rc
  end

  #*******************************************************************************************#
  # Set version id from params                                                                #
  #*******************************************************************************************#
  def set_version_id(version_num)
    return (version_num.blank? ? Version::DESIGN_VERSION.id : version_num.to_i)
  end

  #*******************************************************************************************#
  # Find oligos by project/gene, for specific script/version                                  #
  #*******************************************************************************************#
  def get_oligos_by_gene(project, genes, version_id=Version::DESIGN_VERSION_ID)
    condition_array = ['gene_code IN (?)', genes]

    #Determine which table to retrieve oligos from (Pilot, Archive or Current  ..oligo_designs)
    @model = get_model_name(version_id)

    @oligo_designs = @model.constantize.find_selectors_with_conditions(condition_array, version_id)
    return @oligo_designs
  end

  #*******************************************************************************************#
  # Find oligos by id, for specific script/version                                            #
  #*******************************************************************************************#
  def get_oligos_by_id(ids, version_id=Version::DESIGN_VERSION_ID)
    #Determine which table to retrieve oligos from (Pilot, Archive or Current  ..oligo_designs)
    @model = get_model_name(version_id)

    @oligo_designs = @model.constantize.find_with_id_list(ids)
    return @oligo_designs
  end

  #*******************************************************************************************#
  # Determine which model to use for specific script/version                                  #
  #*******************************************************************************************#
  def get_model_name(version_id)
    version = Version.find_by_id(version_id)
    case version.archive_flag
      # 'P' is pilot project; 'A' is archived project; otherwise in current oligo_designs table
      when 'P'
        model = 'PilotOligoDesign'
      when 'A'
        model = 'ArchiveOligoDesign'
      else
        model = 'OligoDesign'
    end
    return model
  end

  #*******************************************************************************************#
  # Increment download counter                                                                #
  #*******************************************************************************************#
  def add_one_to_counter(fld_type)
    case fld_type
      when 'export'
        fld = 'export_cnt'
      when 'zip' 
        fld = 'zipdownload_cnt'
    end

    ExportCount.increment_counter(fld.to_sym, 1) if fld
  end

  #*******************************************************************************************#
  # Export oligo designs to csv file                                                          #
  #*******************************************************************************************#
  def export_designs_csv(oligo_designs)
    xfmt = ExportField::EXPORT_FMT
    csv_string = FasterCSV.generate(:col_sep => "\t") do |csv|
      csv << (ExportField.headings(xfmt) << 'Extract_Date')

      oligo_designs.each do |oligo_design|
        fld_array = []
        oligo_annotation = oligo_design.oligo_annotation

        ExportField.fld_names(xfmt).each do |model, fld|
          if model == 'oligo_design'
            fld_array << oligo_design["#{fld}"] 

          elsif model == 'oligo_annotation'
            fld_array << oligo_annotation["#{fld}"] if oligo_annotation
            fld_array << ' '                        if oligo_annotation.nil?
          end
        end

        csv << (fld_array << Date.today.to_s)
        end
    end
    return csv_string
  end

  #*******************************************************************************************#
  # Download zip file                                                                         #
  #*******************************************************************************************#
  def download_zip_file(version_id=Version::DESIGN_VERSION.id)
    filepath = File.join(RAILS_ROOT, "public", "oligo_exome_V#{version_id}.zip")

    if FileTest.file?(filepath)
      flash[:notice] = "Zip file successfully downloaded"
      send_file(filepath, :disposition => "attachment")
    else
      flash[:notice] = "Error downloading zip file - file not found"
    end
  end

end