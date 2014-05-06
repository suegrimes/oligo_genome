class ApplicationController < ActionController::Base
  protect_from_forgery
  
  include OligoExtensions
  include CoverageDepth
  require 'csv'
  
  helper :all # include all helpers, all the time
  
  # Structure used for converting array into class with label/value pairs, for collection_select
  LabelValue = Struct.new(:label, :value)
 
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '01ace71a5cf310fe9f1ee1867cd1da7b'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  #filter_parameter_logging :password
  
  #*******************************************************************************************#
  # Increment download counter                                                                #
  #*******************************************************************************************#
  def add_one_to_counter(fld_type)
    case fld_type
      when 'export'
        fld = 'export_cnt'
      when 'zip' 
        fld = 'zipdownload_cnt'
    end

    ExportCount.increment_counter(fld.to_sym, 1) if fld
  end
  
end
