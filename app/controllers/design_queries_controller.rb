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
    if !params[:bed_file][:filenm].blank?
      @bed_file = BedFile.new(params[:bed_file])
      if @bed_file.valid?
        @bed_file.save
        rc, @oligo_designs = build_query_from_file(@bed_file.id)
        if rc >= 0
          render :action => :index
        else
          redirect_to :action => :new_query
        end
      end
      
    else
      @design_query = DesignQuery.new(params[:design_query])   
      if @design_query.valid?
        @oligo_designs = build_query_from_coords(params[:design_query])
        render :action => :index
      else
        render :action => :new_query
      end
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
  
  def build_query_from_coords(params)
    oligo_designs = OligoDesign.find(:all, :conditions => ['chromosome_nr = ? AND 
                                           (amplicon_chr_start_pos <= ? AND amplicon_chr_end_pos >= ?)',
                                           params[:chromosome_nr], 
                                           params[:chr_end_pos], params[:chr_start_pos]]) 
    return oligo_designs
  end
  
  def build_query_from_file(id)
    rc, @bed_lines = read_and_validate_bedfile(id)
    condition_array = build_where_clause(@bed_lines)  if rc == 0 
    
    if condition_array && condition_array.size > 0
      oligo_designs = OligoDesign.find(:all, :conditions => condition_array)
    end
    
    return rc, oligo_designs  # nil if oligo_designs not created
  end
  
  def read_and_validate_bedfile(id)
    bad_lines = 0; nr_bases = 0;
    bed_file = BedFile.find(id)
    bfn      = bed_file.filenm.to_s.split('/')[-1]
    bfp      = File.join(BED_ABS_PATH, bfn)
    #bfp      = File.join(RAILS_ROOT, "public", bfn)  # For testing of file doesn't exist
    raw_lines = []; bed_lines = [];
    
    #  Use Ruby IO.foreach instead of FasterCSV to avoid possible issues with single or double quotes on track description lines
    #  Remove comment and track description lines before pushing to @bed_lines array
    IO.foreach(bfp) {|row| raw_lines.push(row.chomp.split("\t")) unless (row[0,1] == '#' || row[0,5] == 'track')}
    
    #   Do some validation here to ensure that there are not too many lines in the file,(and that the file lines are in bed format)
    #   100 lines max?  Performance seems ok for 100 coordinates for a single chromosome, try higher limit, or multiple chromosomes?
    raw_lines.each do |raw_line|
      raw_line[0].gsub!(/chr/,'') # Strip off 'chr' if exists
      if BedFile.bed_line_valid?(raw_line)
        nr_bases += raw_line[2].to_i - raw_line[1].to_i
        bed_lines.push(raw_line)
      else
        bad_lines += 1
      end
    end
    
    if bad_lines > 0 
      if bad_lines < bed_lines.size
        rc = 0
        flash.now[:notice] = 'WARNING: ' + bad_lines.to_s + ' invalid bed format lines found in file and ignored'
      else
        rc = -1
        flash[:error] = 'ERROR: No valid bed format lines found in file: ' + bfn
      end
    end
    
    if nr_bases > 100000
      rc = -2
      flash[:error] = 'ERROR: Genomic space of ' + nr_bases.to_s + ' is too large - please limit to 100k'
    elsif bed_lines.size > 100
      rc = -3
      flash[:error] = 'ERROR: Too many lines in file - please limit to 100 lines'
    end
    
    return rc, bed_lines
  end
  
  def build_where_clause(bed_lines)
    flds_for_where = []
    values_for_where = []
    
    bed_lines.each do |bed_line|
      flds_for_where.push('(chromosome_nr = ? AND (amplicon_chr_start_pos <= ? AND amplicon_chr_end_pos >= ?))')
      values_for_where.push(bed_line[0], bed_line[2], bed_line[1])
    end
    
    if flds_for_where.size > 0 && values_for_where.size > 0
      return [flds_for_where.join(' OR ')].concat(values_for_where)
    else
      return []
    end
  end
  
end