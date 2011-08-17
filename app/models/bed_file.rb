# == Schema Information
#
# Table name: bed_files
#
#  id                  :integer(4)      not null, primary key
#  title               :string(255)
#  filenm              :string(255)
#  filenm_content_type :string(255)
#  filenm_size         :integer(4)
#  updated_by          :integer(4)
#  created_at          :datetime
#

class BedFile < ActiveRecord::Base
  # default directory for upload_column is RAILS_ROOT/public 
  upload_column :filenm,   :store_dir => 'bed_files',
                           :extensions => %w(bed txt)
                              
  validates_integrity_of :filenm, :message => "file must be tab-delimited BED file of type .bed or .txt", :allow_nil => true
  
  def self.bed_line_valid?(bed_line)
    return false if !bed_line.is_a? Array || bed_line.size < 3
    chr_valid = OligoDesign::CHROMOSOMES.include?(bed_line[0])
    chr_start_valid = bed_line[1].to_i > 0
    chr_end_valid   = bed_line[2].to_i > 0 && bed_line[2].to_i >= bed_line[1].to_i
    return (chr_valid && chr_start_valid && chr_end_valid)
  end

end
