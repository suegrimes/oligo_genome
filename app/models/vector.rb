# == Schema Information
#
# Table name: vectors
#
#  id         :integer(4)      not null, primary key
#  vector     :string(50)      default(""), not null
#  u_vector   :string(50)
#  created_at :datetime
#  updated_at :timestamp
#

class Vector < ActiveRecord::Base
#VECTOR = 'ACGATAACGGTACAAGGCTAAAGCTTTGCTAACGGTCGAG'
VECTOR = self.find(1).vector
UVECTOR = self.find(1).u_vector
end
