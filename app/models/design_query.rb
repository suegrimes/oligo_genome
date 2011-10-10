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
