class HelpController < ApplicationController
  skip_before_filter :login_required
  FILE_PATH = File.join(RAILS_ROOT, "public/files")
  
  def technology
  end

  def statistics
    @table1 = read_table(File.join(FILE_PATH, "Selector_Stats_06072011.txt"))
  end
  
  def protocol 
  end

protected
  def read_table(file_path)
    FasterCSV.read(file_path, {:col_sep => "\t"})
  end
end
