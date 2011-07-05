# == Schema Information
#
# Table name: bed_files
#

class BedFile < ActiveRecord::Base
  # default directory for upload_column is RAILS_ROOT/public 
  upload_column :filenm,   :store_dir => 'bed_files',
                           :extensions => %w(bed txt)
                              
  validates_integrity_of :filenm, :message => "file must be tab-delimited BED file of type .bed or .txt", :allow_nil => true
  
end
