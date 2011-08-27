# == Schema Information
#
# Table name: oligo_annotations
#
#  id              :integer(4)      not null, primary key
#  oligo_design_id :integer(4)      not null
#  oligo_name      :string(100)
#  sel_5prime_U0   :integer(2)      default(0)
#  sel_5prime_U1   :integer(2)      default(0)
#  sel_5prime_U2   :integer(2)
#  sel_5prime_GC   :decimal(6, 4)   default(0.0)
#  sel_3prime_U0   :integer(2)
#  sel_3prime_U1   :integer(2)
#  sel_3prime_U2   :integer(2)
#  sel_3prime_GC   :decimal(6, 4)
#  sel_paralog_cnt :integer(2)      default(0), not null
#  version_id      :integer(2)
#  created_at      :datetime
#  updated_at      :timestamp
#

class OligoAnnotation < ActiveRecord::Base
  
  belongs_to :oligo_design
  
end 
