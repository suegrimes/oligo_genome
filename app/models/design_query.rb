# == Schema Information
#
# Table name: design_queries
#
#  chromosome_nr :string
#  chr_start_pos :integer
#  chr_end_pos   :integer
#

class DesignQuery < NoTable
  class << self
    def table_name
      self.name.tableize
    end
  end
  
  #attr_accessable :chromosome_nr, :chr_start_pos, :chr_end_pos, :sel_5prime_U0, :sel_3prime_U0, :sel_paralog_cnt
      
  column :chromosome_nr,   :string
  column :chr_start_pos,   :integer
  column :chr_end_pos,     :integer
  column :enzyme_code,     :string
  column :sel_3prime_U0,   :integer
  column :sel_5prime_U0,   :integer
  column :sel_paralog_cnt, :integer
  column :tier_nr,         :string
                              
  validates_inclusion_of :chromosome_nr, :in => OligoDesign::CHROMOSOMES.push(''), :message => "is not a valid chromosome"
  validates_numericality_of :chr_start_pos, :chr_end_pos, :sel_3prime_U0, :sel_5prime_U0, :sel_paralog_cnt, 
                  {:only_integer => true, :allow_nil => true, :message => "is not an integer"}
  validates_presence_of :chromosome_nr, :chr_start_pos, :chr_end_pos
  
  validate :chr_coord, :if => Proc.new{|query| !query.chromosome_nr.blank? && !query.chr_start_pos.blank? && !query.chr_end_pos.blank?}
  
  ALL_FLDS     = %w{chromosome_nr chr_start_pos chr_end_pos enzyme_code sel_3prime_U0 sel_5prime_U0 sel_paralog_cnt tier_nr}
  
  MAX_BED_LINES = 50
  MAX_BASES = 1000000

  #*******************************************************************************************#
  # Build and execute query based on up to 500 lines of chromosome coordinates in bed format  #
  #*******************************************************************************************#
  def self.query_from_coords(bed_lines, params)
    condition_array = self.build_where_clause(bed_lines, params)
    
    if condition_array && condition_array.size > 0
      oligo_designs = OligoDesign.find_and_sort_for_query(condition_array)
    end
    
    return oligo_designs  # nil if oligo_designs not created
  end
  
  #*******************************************************************************************#
  # Build SQL where clause based on supplied coordinates                                      #
  #*******************************************************************************************#
  def self.build_where_clause(bed_lines, params)
    flds_for_where = []
    values_for_where = []
    
    bed_lines.each do |bed_line|
      flds_for_where.push('(chromosome_nr = ? AND amplicon_chr_start_pos <= ? AND amplicon_chr_end_pos >= ?)')
      values_for_where.push(bed_line[0], bed_line[2], bed_line[1])
    end
    
    if flds_for_where.size > 0 && values_for_where.size > 0
      where_for_coord = ['(' + flds_for_where.join(' OR ') + ')'].concat(values_for_where)
      where_for_exclusions = self.build_exclusions(params)
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
  
  def self.build_exclusions(params)
    flds_for_where = []
    values_for_where = []
    filter_notes = []
    qparams = params[:design_query]
    
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
    
    if qparams   
    if qparams[:sel_5prime_U0] && qparams[:sel_5prime_U0].to_i > 0
      flds_for_where.push('oligo_annotations.sel_5prime_U0 <= ?')
      values_for_where.push(qparams[:sel_5prime_U0].to_i)
      filter_notes.push('5prime U0 > ' + qparams[:sel_5prime_U0])
    end
    
    if qparams[:sel_3prime_U0] && qparams[:sel_3prime_U0].to_i > 0
      flds_for_where.push('oligo_annotations.sel_3prime_U0 <= ?')
      values_for_where.push(qparams[:sel_3prime_U0].to_i)
      filter_notes.push('3prime U0 > ' + qparams[:sel_3prime_U0])
    end
    
    if qparams[:sel_paralog_cnt] && !qparams[:sel_paralog_cnt].blank?
      flds_for_where.push('oligo_annotations.sel_paralog_cnt <= ?')
      values_for_where.push(qparams[:sel_paralog_cnt].to_i)
      filter_notes.push('Paralogs > ' + qparams[:sel_paralog_cnt])
    end
    end
  
    @filter_text = (filter_notes.empty? ? '' : 'FILTER (exclude): ' + filter_notes.join('; '))
    
    if flds_for_where.size > 0 && values_for_where.size > 0
      return [flds_for_where.join(' AND ')].concat(values_for_where)
    else
      return []
    end
  end
  
  
private
  def chr_coord
    unless chr_end_pos > chr_start_pos
      errors.add(:chr_end_pos, "must be greater than start position")
    end
    unless (chr_end_pos - chr_start_pos) < MAX_BASES
      errors.add(:chr_end_pos, "must be within #{MAX_BASES} of start position")
    end
  end
end
