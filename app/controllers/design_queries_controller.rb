class DesignQueriesController < ApplicationController
  #*******************************************************************************************#
  # Methods for input of parameters for retrieval of specific oligo designs                   #
  #*******************************************************************************************#
  def new_query
    @design_query = DesignQuery.new
    @enzymes = []
    OligoDesign::ENZYMES.each {|enzyme| @enzymes.push([enzyme, false])}
  end
  
  def file_upload
    uploaded_io = params[:filenm]
    File.open(Rails.root.join(BED_ABS_PATH, uploaded_io.original_filename), 'w') do |file|
      file.write(uploaded_io.read)
    end
    redirect_to(:action => 'index', :filnm => uploaded_io)
    return
  end
  
  def index_debug_file
    params[:bed_file] = 'chr1_coord_jb.bed'
    bed_errors, @bed_lines = BedFile.parse_bedfile(params[:bed_file])
    @test = DesignQuery.build_where_clause(@bed_lines, [])
    @oligo_designs = OligoDesign.find_and_sort_for_query(@test)
    render :action => :debug
  end
  
  def index_debug_coord
    #params[:design_query] = {:chromosome_nr => '1',
     #                       :chr_start_pos => 1986764,
      #                       :chr_end_pos   => 1989000}
    qparams = params[:design_query]
    @bed_lines = [[qparams[:chromosome_nr], qparams[:chr_start_pos].to_i, qparams[:chr_end_pos].to_i]]
    @oligo_designs = DesignQuery.query_from_coords(@bed_lines, params)
    @test = calculate_depth(@oligo_designs, @bed_lines) if @oligo_designs.size > 0
    render :action => :debug
  end

  #*******************************************************************************************#
  # Method for listing oligo designs, based on parameters entered above                       #
  #*******************************************************************************************#
  def index
    params[:bed_file] = 'chr1_coord_jb.bed'
    
    if !params[:bed_file].blank?
      bed_errors, @bed_lines = BedFile.parse_bedfile(params[:bed_file])
    
      if !@bed_lines.empty?
        @oligo_designs = DesignQuery.query_from_coords(@bed_lines, params)
        @depth_array = calculate_depth(@oligo_designs, @bed_lines)
        handle_bed_errors(params[:bed_file], bed_errors)  # Warning messages if some bed lines ignored
        render :action => :index
      
      else
        @design_query = DesignQuery.new
        @enzymes = []
        OligoDesign::ENZYMES.each {|enzyme| @enzymes.push([enzyme, false])}
        handle_bed_errors(params[:bed_file], bed_errors) # Error messages for invalid bed file
        render :action => :new_query
      end
     
    else
      @design_query = DesignQuery.new(params[:design_query])   
      if @design_query.valid?
        qparams = params[:design_query]
        @bed_lines = [[qparams[:chromosome_nr].to_s, qparams[:chr_start_pos].to_i, qparams[:chr_end_pos].to_i]]
        @oligo_designs = DesignQuery.query_from_coords(@bed_lines, params)  
        @depth_array = calculate_depth(@oligo_designs, @bed_lines) if @oligo_designs.size > 0
        render :action => :index
        
      else
        @enzymes = []
        OligoDesign::ENZYMES.each {|enzyme| @enzymes.push([enzyme, false])}  
        render :action => :new_query
      end
    end   
  end
  
  #*******************************************************************************************#
  # Export to text or bed format                                                              #
  #*******************************************************************************************#
  def export_design
    add_one_to_counter('export')
#
    export_type = (params[:commit] == 'Export Oligos'? 'T1' : 'B1')
    design_ids = params[:export_id]
    @oligo_designs = OligoDesign.find_and_sort_for_query(["id IN (?)", design_ids])
    file_basename  = "oligodesigns_" + Date.today.to_s

    case export_type
      when 'B1'
        @filename = file_basename + ".bed"
        write_bed_file(@filename, @oligo_designs)
        send_file(@filename)
      
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
  # Write .bed format file                                                                    #
  #*******************************************************************************************#
  def write_bed_file(filename, oligo_designs)
    CSV.open(filename, "w", {:col_sep => "\t", :quote_char => "'", :force_quotes => false}) do |csv|
      csv << ['track name="OligoGenome" description="Oligos from Stanford OligoGenome resource" visibility=2 itemRgb="On"']
      oligo_designs.each do |oligo|
        csv << ['chr' + oligo.chromosome_nr, oligo.amplicon_chr_bed_start, oligo.amplicon_chr_end_pos, oligo.oligo_name,
        0, oligo.strand, oligo.amplicon_chr_bed_start, oligo.amplicon_chr_end_pos, oligo.ucsc_track_color]
      end
    end
  end
  
  #*******************************************************************************************#
  # Export oligo designs to csv file                                                          #
  #*******************************************************************************************#
  def export_designs_csv(oligo_designs)
    xfmt = ExportField::EXPORT_FMT
    csv_string = CSV.generate(:col_sep => "\t") do |csv|
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
  
  #*******************************************************************************************#
  # Populate error messages as appropriate                                                    #
  #*******************************************************************************************#
  def handle_bed_errors(bed_fn, bed_errors)
    nr_bases = bed_errors[0]
    bed_lines_size = bed_errors[1]
    bad_lines = bed_errors[2]
    
    rc = 0
    if bad_lines > 0 
      if bad_lines < bed_lines_size
        rc = 0
        flash.now[:notice] = 'WARNING: ' + bad_lines.to_s + ' invalid bed format lines found in file and ignored'
      else
        rc = -1
        flash[:error] = 'ERROR: No valid bed format lines found in file: ' + bed_fn
      end
    end
    
    if nr_bases > DesignQuery::MAX_BASES
      rc = -2
      flash[:error] = 'ERROR: Genomic space of ' + nr_bases.to_s + ' is too large - please limit to ' + DesignQuery::MAX_BASES
    elsif bed_lines_size > DesignQuery::MAX_BED_LINES
      rc = -3
      flash[:error] = "ERROR: Too many lines in file - please limit to #{DesignQuery::MAX_BED_LINES} lines"
    end
    return rc
  end
end