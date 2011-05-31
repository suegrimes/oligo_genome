# == Schema Information
#
# Table name: oligo_designs
#
#  id                     :integer(4)      not null, primary key
#  oligo_name             :string(100)     default(""), not null
#  chromosome_nr          :string(3)
#  enzyme_code            :string(20)
#  annotation_codes       :string(20)
#  other_annotations      :string(20)
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
  acts_as_commentable
 
  has_one  :oligo_annotation, :foreign_key => :oligo_design_id
  
  validates_uniqueness_of :oligo_name,
                          :on  => :create  
                          
  named_scope :curr_ver, :conditions => ['version_id = (?)', Version::DESIGN_VERSION.id ]
  
  ENZYMES = ['BfaI', 'CviQI', 'MseI', 'Sau3AI']

  #****************************************************************************************#
  #  Define virtual attributes                                                             #
  #****************************************************************************************#
  
  def polarity
    (sel_polarity == 'p' ? 'plus' : 'minus')
  end
  
  def selector_u
    [usel_5prime, Vector::UVECTOR, usel_3prime].join
  end
  
  def selector
    [sel_5prime, Vector::VECTOR, sel_3prime].join
  end
  
  #****************************************************************************************#
  #  Class find methods   - Oligos                                                         #
  #****************************************************************************************#
  
#  def self.find_using_oligo_name_id(oligo_name)
#    # Use id or gene_code index to speed retrieval.
#    # Note: curr_oligo_format?, and get_gene_from_name are in OligoExtensions module
#    
#    if curr_oligo_format?(oligo_name)                            
#      # oligo name in current format, => use id as index
#      oligo_array  = oligo_name.split(/_/)
#      oligo_design = self.find_by_oligo_name_and_id(oligo_name, oligo_array[0])
#    else
#      # oligo name in old format => cannot use id, use gene code instead
#      #gene_code    = self.get_gene_from_name(oligo_name, false)
#      gene_code    = get_gene_from_oligo_name(oligo_name, false) 
#      oligo_design = self.find_by_oligo_name_and_gene_code(oligo_name, gene_code)
#    end
#    
#    return oligo_design
#  end
#  
#  def self.find_selectors_with_conditions(condition_array, version_id=Version::DESIGN_VERSION_ID)
#    condition_array[0] += ' AND version_id = ?'
#    condition_array.push(version_id)
#    
#    self.qcpassed.find(:all,
#                       :order => 'gene_code, enzyme_code',                               
#                       :conditions => condition_array) 
#  end
#  
  def self.find_with_id_list(id_list)
    self.find(:all, :include => :oligo_annotation,
                    :order => 'chromosome_nr, amplicon_chr_start_pos',
                    :conditions => ["id IN (?)", id_list])
  end
  
end
