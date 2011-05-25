# == Schema Information
#
# Table name: vectors
#
#  id          :integer(4)      not null, primary key
#  description :string(50)
#  vector      :string(75)      default(""), not null
#  u_vector    :string(75)
#  created_at  :datetime
#  updated_at  :timestamp
#

class Vector < ActiveRecord::Base
#VECTOR = 'ACGATAACGGTACAAGGCTAAAGCTTTGCTAACGGTCGAG'
VECTOR = self.find(1).vector
end
