# == Schema Information
#
# Table name: design_queries
#
#  chromosome_nr :string(3)
#  chr_start_pos :integer(4)
#  chr_end_pos   :integer(4)
#  bed_file      :string(255)
#  content_type  :string
#

class DesignQuery < NoTable
  class << self
    def table_name
      self.name.tableize
    end
  end
  
  column :chromosome_nr, :string
  column :chr_start_pos, :integer
  column :chr_end_pos,   :integer
                              
  validates_inclusion_of :chromosome_nr, :in => OligoDesign::CHROMOSOMES.push(''), 
                                         :message => "is not a valid chromosome"
  validates_numericality_of :chr_start_pos, :only_integer => true, :allow_nil => true, :message => "is not an integer"
  validates_numericality_of :chr_end_pos, :only_integer => true, :allow_nil => true, :message => "is not an integer"
  
  validate :chr_coord, :if => Proc.new{|query| !query.chromosome_nr.blank? || !query.chr_start_pos.blank? || !query.chr_end_pos.blank?}
  
  ALL_FLDS     = %w{chromosome_nr, chr_start_pos, chr_end_pos}
  
  MAX_BED_LINES = 500
  MAX_BASES = 1000000
  
private
  def chr_coord
    unless !chromosome_nr.blank?
      errors.add(:chromosome_nr, "cannot be blank")
    end
    unless !chr_start_pos.blank? 
      errors.add(:chr_start_pos, "cannot be blank")
    end
    unless !chr_end_pos.blank? 
      errors.add(:chr_end_pos, "cannot be blank")
    end
    unless chr_end_pos > chr_start_pos
      errors.add(:chr_end_pos, "must be greater than start position")
    end
    unless (chr_end_pos - chr_start_pos) < MAX_BASES
      errors.add(:chr_end_pos, "must be within #{MAX_BASES} of start position")
    end
  end
end
