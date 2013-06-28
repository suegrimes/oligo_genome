class HelpController < ApplicationController
  skip_before_filter :login_required
  
  FILE_PATH = Rails.root.join('app', 'assets', 'files')
  
  def technology
  end

  def statistics
    @table1 = read_table(File.join(FILE_PATH, "Selector_Stats_06072011.txt"))
    #send_file(File.join(FILE_PATH, "Selector_Stats_06072011.txt"))
  end
  
  def protocol 
  end

  def annotations
  end

  def ucsc_view
  end

  def contact
  end

protected
  def read_table(file_path)
    CSV.read(file_path, {:col_sep => "\t"})
  end
end
