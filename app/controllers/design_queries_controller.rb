class DesignQueriesController < ApplicationController
  #*******************************************************************************************#
  # Methods for input of parameters for retrieval of specific oligo designs                   #
  #*******************************************************************************************#
  def new_query
    @design_query = DesignQuery.new
  end

  #*******************************************************************************************#
  # Method for listing oligo designs, based on parameters entered above                       #
  #*******************************************************************************************#
  def index
    @design_query = DesignQuery.new(params[:design_query])
    
    if @design_query.valid?
       @oligo_designs = OligoDesign.find(:all, 
                                         :conditions => ['chromosome_nr = ? AND (amplicon_chr_start_pos <= ? AND amplicon_chr_end_pos >= ?)',
                                                         params[:design_query][:chromosome_nr], 
                                                         params[:design_query][:chr_end_pos], params[:design_query][:chr_start_pos]])                                      
      render :action => :index
    else
      render :action => :new_query
    end
  end

  def export_design
    add_one_to_counter('export')
#
    export_type = 'T1'
    design_ids = params[:export_id]
    @oligo_designs = OligoDesign.find_with_id_list(design_ids)
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
  
private
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
            fld_array << oligo_design.send(fld) 

          elsif model == 'oligo_annotation'
            fld_array << oligo_annotation.send(fld) if oligo_annotation
            fld_array << ' '                        if oligo_annotation.nil?
          end
        end

        csv << (fld_array << Date.today.to_s)
        end
    end
    return csv_string
  end

end