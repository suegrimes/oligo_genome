# == Schema Information
#
# Table name: design_queries
#
#  chromosome_nr :string(3)
#  chr_start_pos :integer(4)
#  chr_end_pos   :integer(4)
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
  
  #validates_presence_of :chromosome_nr, chr_start_pos, chr_end_pos
  validates_inclusion_of :chromosome_nr, :in => %w{1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y}, :message => "is blank or not a valid chromosome"
  validates_numericality_of :chr_start_pos, :only_integer => true, :allow_nil => false, :message => "is blank or not an integer"
  validates_numericality_of :chr_end_pos, :only_integer => true, :allow_nil => false, :message => "is blank or not an integer"
  validate :end_gt_start?, :if => Proc.new{|query| !query.chr_start_pos.blank? && !query.chr_end_pos.blank?}
  
  ALL_FLDS     = %w{chromosome_nr, chr_start_pos, chr_end_pos}
  
private
  def end_gt_start?
    unless chr_end_pos > chr_start_pos
      errors.add(:chr_end_pos, "must be greater than start position")
    end
  end
end
