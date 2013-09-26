# == Schema Information
#
# Table name: oligo_designs
#
#  id                     :integer(4)      not null, primary key
#  oligo_name             :string(100)     default(""), not null
#  chromosome_nr          :string(3)
#  enzyme_code            :string(20)
#  selector_nr            :integer(4)
#  annotation_codes       :string(20)
#  sel_polarity           :string(1)
#  sel_5prime             :string(30)
#  sel_3prime             :string(30)
#  usel_5prime            :string(30)
#  usel_3prime            :string(30)
#  amplicon_chr_start_pos :integer(4)
#  amplicon_chr_end_pos   :integer(4)
#  amplicon_length        :integer(4)
#  version_id             :integer(4)
#  genome_build           :string(25)
#  created_at             :datetime
#  updated_at             :datetime
#

class OligoDesign < ActiveRecord::Base 
  has_one  :oligo_annotation, :foreign_key => :oligo_design_id
  
  validates_uniqueness_of :oligo_name,
                          :on  => :create  
                          
  #named_scope :curr_ver, :conditions => ['version_id = (?)', Version::DESIGN_VERSION.id ]
  scope :curr_ver, where(:version_id => Version::DESIGN_VERSION.id)
  
  CHROMOSOMES = %w{1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y}
  ENZYMES = %w{BfaI CviQI MseI Sau3AI}

  #****************************************************************************************#
  #  Define virtual attributes                                                             #
  #****************************************************************************************#
  
  def polarity
    (sel_polarity == 'p' ? 'plus' : 'minus')
  end
  
  def strand
    (sel_polarity == 'p' ? '+' : '-')
  end
  
  def amplicon_chr_bed_start
    (amplicon_chr_start_pos - 1)
  end
  
  def selector_u
    [usel_5prime, Vector::UVECTOR, usel_3prime].join
  end
  
  def selector
    [sel_5prime, Vector::VECTOR, sel_3prime].join
  end
  
  def ucsc_track_color
    case enzyme_code
      when 'BfaI'   then '255,0,0'
      when 'MseI'   then '0,255,0'
      when 'CviQI'  then '0,0,255'
      when 'Sau3AI' then '255,255,0'
      else '192,192,192'
    end
  end
  
  #****************************************************************************************#
  #  Class find methods                                                                    #
  #****************************************************************************************#
   
  def self.find_and_sort_for_query(condition_array)
    self.where(*condition_array).order("chromosome_nr, amplicon_chr_start_pos").includes(:oligo_annotation).all
  end
  
end
