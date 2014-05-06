class BedFile
  require "fileutils"
  #@@bed_dir = File.join(RAILS_ROOT, 'public', 'bed_files')
  @@bed_dir = File.join("#{Rails.root}", "app/assets/", "bed_files")
  
  #*******************************************************************************************#
  # Read bed file, removing comment and track lines                                           #
  #*******************************************************************************************#
  def self.parse_bedfile(bed_fn)
    bfp      = File.join(@@bed_dir, bed_fn)
    bf_lines = []; bed_lines = []; bed_errors = [];
    
    #  Use Ruby IO.foreach instead of FasterCSV to avoid possible issues with single or double quotes on track description lines
    #  Remove 'chr' at beginning of of chromosome# (if exists); convert chromosome coordinates to integer
    #  Remove comment and track description lines before pushing to @bed_lines array
    IO.foreach(bfp) {|row| bf_lines.push(self.coord_convert(row.chomp.split("\t"), 'bed2gff')) unless (row[0,1] == '#' || row[0,5] == 'track')}
    
    if bf_lines.size > 0
      bed_errors, val_lines  = self.validate_bed_lines(bf_lines)
      bed_lines  = self.flatten_bed_lines(val_lines)        
    else
      bed_errors = [0,0,1]
    end
    
    return bed_errors, bed_lines
  end
  
  #*******************************************************************************************#
  # Convert chromosome start position to/from bed format                                      #
  #*******************************************************************************************#
  def self.coord_convert(bed_line, convert='bed2gff')
    # Strip off 'chr' if exists 
    # Adjust chromosome start position for conversion to or from bed format
    bed_line[0].gsub!(/chr/,'')                                                    
    coord_adjust = (convert == 'bed2gff' ? 1 : (convert == 'gff2bed' ? -1 : 0))
    bed_line[1] = (convert == 'bed2gff' ? bed_line[1].to_i + coord_adjust : bed_line[1].to_i)  
    bed_line[2] = bed_line[2].to_i 
    return bed_line
  end
  
  #*******************************************************************************************#
  # Remove any invalid bed file lines                                                         #
  #*******************************************************************************************#
  def self.validate_bed_lines(bf_lines)  
    val_lines = []; bad_lines = 0;
    bf_lines.each {|bf_line| (self.bed_line_valid?(bf_line) ? val_lines.push(bf_line) : bad_lines += 1)}
    return [0, bf_lines.size, bad_lines], val_lines
  end
  
  def self.bed_line_valid?(bed_line)
    return false if !bed_line.is_a? Array || bed_line.size < 3
    chr_valid = OligoDesign::CHROMOSOMES.include?(bed_line[0])
    chr_start_valid = bed_line[1].to_i > 0
    chr_end_valid   = bed_line[2].to_i > 0 && bed_line[2].to_i >= bed_line[1].to_i
    return (chr_valid && chr_start_valid && chr_end_valid)
  end
  
  #*******************************************************************************************#
  # Flatten bed file coordinates into unique contiguous blocks                                #
  #*******************************************************************************************#
  def self.flatten_bed_lines(bf_lines)
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
  
end
