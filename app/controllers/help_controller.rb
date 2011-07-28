class HelpController < ApplicationController
  skip_before_filter :login_required
  FILE_PATH = File.join(RAILS_ROOT, "public/files")
  
  def technology
  end

  def statistics
    #@table1 = read_table(File.join(FILE_PATH, "selector_stats_06072011.txt"))
    send_file(File.join(FILE_PATH, "selector_stats_06072011.txt"))
  end
  
  def protocol 
  end

protected
  def read_table(file_path)
    FasterCSV.read(file_path, {:col_sep => "\t"})
  end
end
