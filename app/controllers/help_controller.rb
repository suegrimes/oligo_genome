class HelpController < ApplicationController
  skip_before_filter :login_required
  FILE_PATH = File.join(RAILS_ROOT, "public/files")
  
  def technology
  end

  def figure_s1
   #file_path = File.join(RAILS_ROOT, "public/images", "Figures_S1_Natsoulis.png")
   #send_file file_path, :type => 'image/png', :disposition => 'inline'
  end
 
  def table_s5
    @table1 = read_table(File.join(FILE_PATH, "Table_S5_Novels_SNVs.txt"))
    #send_file(File.join(FILE_PATH, "Table_S5_Novels_SNVs.txt"), :type => 'text/csv', :disposition => 'inline')
  end
  
  def table_s8
    #@table1 = read_table(File.join(FILE_PATH, "Table_S8_Capture_Oligos.txt"))
    send_file(File.join(FILE_PATH, "Table_S8_Capture_Oligos.txt"), :type => 'text/csv', :disposition => 'inline')
  end

  def statistics
    @table1 = read_table(File.join(FILE_PATH, "oligostats_table2.txt"))
    @table2 = read_table(File.join(FILE_PATH, "oligostats_table3.txt"))
    @table3 = read_table(File.join(FILE_PATH, "oligostats_table4a.txt"))
  end
  
  def annotations 
  end

protected
  def read_table(file_path)
    FasterCSV.read(file_path, {:col_sep => "\t"})
  end
end
