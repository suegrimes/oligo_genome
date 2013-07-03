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
    bed_lines = read_bedfile(25)
    rc, val_lines = validate_bed_lines(25, bed_lines)
    @bed_lines = flatten_bed_lines(val_lines)
    @test = build_where_clause(@bed_lines)
    @oligo_designs = OligoDesign.find_and_sort_for_query(@test)
    render :action => :debug
  end
  
  def index_debug_coord
    #params[:design_query] = {:chromosome_nr => '1',
     #                       :chr_start_pos => 1986764,
      #                       :chr_end_pos   => 1989000}
    @oligo_designs = build_query_from_coords(params)
    @bed_lines = [[params[:design_query][:chromosome_nr], params[:design_query][:chr_start_pos].to_i, params[:design_query][:chr_end_pos].to_i]]
    @test = calculate_depth(@oligo_designs, @bed_lines) if @oligo_designs.size > 0
    render :action => :debug
  end

  #*******************************************************************************************#
  # Method for listing oligo designs, based on parameters entered above                       #
  #*******************************************************************************************#
  def index

    if !params[:filenm].blank?
    
      @bed_file = BedFile.new(params[:filenm])
      
      rc1 = (@bed_file.filenm.nil? ? -5 : 0)  # Filename set to nil by upload_column plug-in if invalid file extension
      if rc1 == 0
        @bed_file.save                                               
        rc2, @oligo_designs = build_query_from_file(@bed_file.id, params)
        @depth_array = calculate_depth(@oligo_designs, @bed_lines)  if rc2 == 0 && !@oligo_designs.nil?
      else
        flash.now[:error] = 'ERROR: File is not in .bed format, or is not a recognized file type - please use .bed or .txt'
      end
      
      if rc1 < 0 || rc2 < 0
        @design_query = DesignQuery.new
        @enzymes = []
        OligoDesign::ENZYMES.each {|enzyme| @enzymes.push([enzyme, false])}
        render :action => :new_query
      else
        render :action => :index
      end
 
    else
      @design_query = DesignQuery.new(params[:design_query])   
      if @design_query.valid?
        @oligo_designs = build_query_from_coords(params)
        qparam = params[:design_query]
        @bed_lines = [[qparam[:chromosome_nr].to_s, qparam[:chr_start_pos].to_i, qparam[:chr_end_pos].to_i]]
        @depth_array = calculate_depth(@oligo_designs, @bed_lines) if @oligo_designs.size > 0
        render :action => :index
      else
        @enzymes = []
        OligoDesign::ENZYMES.each {|enzyme| @enzymes.push([enzyme, false])}
        @bed_file = BedFile.new
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
    FasterCSV.open(filename, "w", {:col_sep => "\t", :quote_char => "'", :force_quotes => false}) do |csv|
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
  
  #*******************************************************************************************#
  # Build and execute query based on single set of chromosome coordinates                     #
  #*******************************************************************************************#
  def build_query_from_coords(params)
    coord_array = [[params[:design_query][:chromosome_nr], params[:design_query][:chr_start_pos].to_i, params[:design_query][:chr_end_pos].to_i]]
    @condition_array = build_where_clause(coord_array, params)
    oligo_designs = OligoDesign.find_and_sort_for_query(@condition_array)
    return oligo_designs
  end
  
  #*******************************************************************************************#
  # Build and execute query based on bed file containing up to 500 lines of coordinates       #
  #*******************************************************************************************#
  def build_query_from_file(id, params)
    bed_raw_lines = read_bedfile(id)
    
    if bed_raw_lines.size > 0
      rc, val_lines   = validate_bed_lines(id, bed_raw_lines)
      @bed_lines      = flatten_bed_lines(val_lines)            if rc == 0
      condition_array = build_where_clause(@bed_lines, params)  if rc == 0
    else
      rc = handle_bed_errors(id, 0, 0, 1)
    end
    
    if condition_array && condition_array.size > 0
      oligo_designs = OligoDesign.find_and_sort_for_query(condition_array)
    end
    
    return rc, oligo_designs  # nil if oligo_designs not created
  end
  
  #*******************************************************************************************#
  # Read bed file, removing comment and track lines                                           #
  #*******************************************************************************************#
  def read_bedfile(id)
    bed_file = BedFile.find(id)
    bfn      = bed_file.filenm.to_s.split('/')[-1]
    bfp      = File.join(BED_ABS_PATH, bfn)
    #bfp      = File.join(RAILS_ROOT, "public", bfn)  # For testing of file doesn't exist
    bf_lines = []
    
    #  Use Ruby IO.foreach instead of FasterCSV to avoid possible issues with single or double quotes on track description lines
    #  Remove comment and track description lines before pushing to @bed_lines array
    IO.foreach(bfp) {|row| bf_lines.push(row.chomp.split("\t")) unless (row[0,1] == '#' || row[0,5] == 'track')}
    
    return (bf_lines.empty? ? [] : bf_lines)
  end
  
  #*******************************************************************************************#
  # Remove any invalid bed file lines                                                         #
  #*******************************************************************************************#
  def validate_bed_lines(id, bf_lines)  
    val_lines = []; bad_lines = 0;
    
    # Remove 'chr' at beginning of of chromosome# (if exists); convert chromosome coordinates to integer
    bf_lines.each {|row| row = coord_convert(row, 'bed2gff')}
    bf_lines.each {|bf_line| (BedFile.bed_line_valid?(bf_line) ? val_lines.push(bf_line) : bad_lines += 1)}

    rc = handle_bed_errors(id, 0, bf_lines.size, bad_lines)
    return rc, val_lines
  end
  
  #*******************************************************************************************#
  # Flatten bed file coordinates into unique contiguous blocks                                #
  #*******************************************************************************************#
  def flatten_bed_lines(bf_lines)
    bedf_lines = []; nr_bases = 0;
    # Sort file by chromosome, start position, end position
    srt_lines = bf_lines.sort_by {|row| [row[0], row[1], row[2]]}   
    
    chr_contig = srt_lines[0]
    srt_lines.each do |srt_line|
      if srt_line[0] == chr_contig[0] && (srt_line[1] <= chr_contig[2])
        chr_contig[2] = srt_line[2]    if srt_line[2] >  chr_contig[2]
      else
        nr_bases += chr_contig[2] - chr_contig[1]
        bedf_lines.push(chr_contig)
        chr_contig = srt_line
      end
    end
    bedf_lines.push(chr_contig)
    return bedf_lines
  end
  
  #*******************************************************************************************#
  # Populate error messages as appropriate                                                    #
  #*******************************************************************************************#
  def handle_bed_errors(id, nr_bases, bed_lines_size, bad_lines)
    bfn = BedFile.find(id).filenm.to_s.split('/')[-1]
    rc = 0
    if bad_lines > 0 
      if bad_lines < bed_lines_size
        rc = 0
        flash.now[:notice] = 'WARNING: ' + bad_lines.to_s + ' invalid bed format lines found in file and ignored'
      else
        rc = -1
        flash[:error] = 'ERROR: No valid bed format lines found in file: ' + bfn
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
  
  #*******************************************************************************************#
  # Build SQL where clause based on supplied coordinates                                      #
  #*******************************************************************************************#
  def build_where_clause(bed_lines, params)
    flds_for_where = []
    values_for_where = []
    
    bed_lines.each do |bed_line|
      flds_for_where.push('(chromosome_nr = ? AND amplicon_chr_start_pos <= ? AND amplicon_chr_end_pos >= ?)')
      values_for_where.push(bed_line[0], bed_line[2], bed_line[1])
    end
    
    if flds_for_where.size > 0 && values_for_where.size > 0
      where_for_coord = ['(' + flds_for_where.join(' OR ') + ')'].concat(values_for_where)
      where_for_exclusions = build_exclusions(params)
      if where_for_exclusions.empty?
        return where_for_coord
      else
        where_for_coord[0] = [where_for_coord[0], where_for_exclusions[0]].join(' AND ')
        return where_for_coord.concat(where_for_exclusions[1..-1])
      end
    else
      return []
    end
  end
  
  def build_exclusions(params)
    flds_for_where = []
    values_for_where = []
    filter_notes = []
    
    enzymes = []
    if params[:enzyme_params]
      params[:enzyme_params].each do |enzyme_idx, val|
        enzymes.push(OligoDesign::ENZYMES[enzyme_idx.to_i]) if val
      end
      flds_for_where.push('enzyme_code NOT IN (?)')
      values_for_where.push(enzymes)
      filter_notes.push('Enzymes: ' + enzymes.join(','))
    end
    
    tiers = []
    if params[:tier_params]
      params[:tier_params].each do |tier, val|
        tiers.push(tier.to_i) if val
      end
      flds_for_where.push('tier_nr NOT IN (?)')
      values_for_where.push(tiers)
      filter_notes.push('Tiers: ' + tiers.join(','))
    end
    
    if params[:design_query]   
    if params[:design_query][:sel_5prime_U0] && params[:design_query][:sel_5prime_U0].to_i > 0
      flds_for_where.push('oligo_annotations.sel_5prime_U0 <= ?')
      values_for_where.push(params[:design_query][:sel_5prime_U0].to_i)
      filter_notes.push('5prime U0 > ' + params[:design_query][:sel_5prime_U0])
    end
    
    if params[:design_query][:sel_3prime_U0] && params[:design_query][:sel_3prime_U0].to_i > 0
      flds_for_where.push('oligo_annotations.sel_3prime_U0 <= ?')
      values_for_where.push(params[:design_query][:sel_3prime_U0].to_i)
      filter_notes.push('3prime U0 > ' + params[:design_query][:sel_3prime_U0])
    end
    
    if params[:design_query][:sel_paralog_cnt] && !params[:design_query][:sel_paralog_cnt].blank?
      flds_for_where.push('oligo_annotations.sel_paralog_cnt <= ?')
      values_for_where.push(params[:design_query][:sel_paralog_cnt].to_i)
      filter_notes.push('Paralogs > ' + params[:design_query][:sel_paralog_cnt])
    end
    end
  
    @filter_text = (filter_notes.empty? ? '' : 'FILTER (exclude): ' + filter_notes.join('; '))
    
    if flds_for_where.size > 0 && values_for_where.size > 0
      return [flds_for_where.join(' AND ')].concat(values_for_where)
    else
      return []
    end
  end
  
  #*******************************************************************************************#
  # Convert chromosome start position to/from bed format                                      #
  #*******************************************************************************************#
  def coord_convert(bed_line, convert='bed2gff')
    # Strip off 'chr' if exists 
    # Adjust chromosome start position for conversion to or from bed format
    bed_line[0].gsub!(/chr/,'')                                                    
    coord_adjust = (convert == 'bed2gff' ? 1 : (convert == 'gff2bed' ? -1 : 0))
    bed_line[1] = (convert == 'bed2gff' ? bed_line[1].to_i + coord_adjust : bed_line[1].to_i)  
    bed_line[2] = bed_line[2].to_i 
    return bed_line
  end
  
end