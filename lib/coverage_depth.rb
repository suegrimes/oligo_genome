module CoverageDepth
  
####################################################################################################################
# calculate_depth:                                                                                                 #
# This method takes an array of hashes holding the oligonucleotide information (oligo_array) and an array holding  #
# the bed interval information (bed_array). It returns an array of arrays holding coverage depth statistics        #
# for each region (first index corresponds to region, second index corresponds to depth, where the last region in  #
# the array is a sum over all regions                                                                              #
####################################################################################################################
def calculate_depth(oligo_array, bed_array)
   
  # Sort oligo_array by chr, start, put in an array (2 lines per oligo: first with amplicon start position, second with amplicon end position)
  oligo_sorted = []
  #oligo_hash.values.sort_by {|x| [x[:chromosome_nr], x[:amplicon_chr_start_pos]]}.each { |x| oligo_sorted.push([x[:chromosome_nr], x[:amplicon_chr_start_pos], "s"], [x[:chromosome_nr], x[:amplicon_chr_end_pos], "e"]) }
  oligo_array.sort_by {|x| [x[:chromosome_nr], x[:amplicon_chr_start_pos]]}.each { |x| oligo_sorted.push([x[:chromosome_nr], x[:amplicon_chr_start_pos], "s"], [x[:chromosome_nr], x[:amplicon_chr_end_pos], "e"]) }
  oligo_sorted = oligo_sorted.sort_by {|x| [x[0], x[1]]}
  
  # Sort bed_array by chr, start, put in an array
  #bed_sorted = bed_hash.values.sort_by {|x| [x[:chromosome_nr], x[:amplicon_chr_start_pos]]}
  bed_sorted = bed_array.sort_by {|x| [x[0], x[1]]}
  
  # initialize depth variable that will contain all depth counts
  depth = Array.new(bed_sorted.length + 1) { Array.new(1) {0}}

  # iterate over all bed regions
  i, j = 0, -1
  curr_depth, prev_pos = 0, 0
  bed_sorted.each do |interval|
    j += 1
    prev_pos = interval[1]
    
    # while the interval and oligo have the same chromosome, cycle through oligos until an oligo coordinate is past the start of the interval
    while(i < oligo_sorted.length && (interval[0] == oligo_sorted[i][0] && interval[1] > oligo_sorted[i][1] || interval[0] > oligo_sorted[i][0] )) do
      if interval[0] == oligo_sorted[i][0]
        curr_depth += (oligo_sorted[i][2] == "s") ? 1 : -1
      end
      i += 1
    end

    # iterate through oligo regions covering the interval
    while (i < oligo_sorted.length) && (interval[2] >= oligo_sorted[i][1]) do

      # reset current depth and go to next interval if the current oligo has a different chromosome from the interval
      if interval[0] != oligo_sorted[i][0]
#        if curr_depth > 0  # for debugging
#          print "ERR: current depth (#{curr_depth}) > 0 when change chromosome\n"
#          Process.exit()
#        end
        break
      end
      
      # advance through all start or end positions at the current base and record which type (start / end) they are
      minus = 0
      plus = 0
      while i < oligo_sorted.length - 1 and oligo_sorted[i][1] == oligo_sorted[i+1][1]
        plus += 1 if oligo_sorted[i][2] == "s"
        minus += 1 if oligo_sorted[i][2] == "e"
        i += 1
      end 
      plus += 1 if oligo_sorted[i][2] == "s"
      minus += 1 if oligo_sorted[i][2] == "e"
 
      # handle the oligos that are starting at this position
      if plus > 0
        update_depth(depth, j, curr_depth, oligo_sorted[i][1], prev_pos)
        curr_depth += plus
        prev_pos = oligo_sorted[i][1]
      end
      
      # handle the oligos that are ending at this position
      if minus > 0
        update_depth(depth, j, curr_depth, oligo_sorted[i][1] + 1, prev_pos)
        curr_depth -= minus
        prev_pos = oligo_sorted[i][1] + 1
      end

      if minus == 0 and plus ==0
        update_depth(depth, j, curr_depth, interval[2] + 1, prev_pos)
      end
      
      # move to the next oligo
      i += 1
    end
    
    # handle the oligo that occurs past the end of the interval
    update_depth(depth, j, curr_depth, interval[2] + 1, prev_pos)

  end
  
  return depth
end

####################################################################################################################
# depth_rpt:                                                                                                       #
# This method takes the depth object return by calculate_depth and the array containing bed regions (bed_array)    #
# and creates a formatted array of depth statistics for printing.                                                  #
# bed_array - [0]=chromosome, [1]=start position, [2]=end position                                                 #                                                                             #
####################################################################################################################
def depth_rpt(depth, bed_array)
  bed_sorted = bed_array.sort_by {|x| [x[0], x[1]]}
  tot_len = 0
  rpt_array = []
  
  # print out depths at each region individually
  for j in (0 .. bed_sorted.length - 1)
    len = bed_sorted[j][2] - bed_sorted[j][1] + 1
    tot_len += len    
    
    rpt_array.push(['H1', ['Region ', bed_sorted[j][0], ':', bed_sorted[j][1], "-", bed_sorted[j][2]].join])  ## Table header
    rpt_array.push(['H2', 'Depth', 'Bases at depth', 'Bases in interval', 'Percent bases at depth']) ## Column Names

    for k in (0 .. depth[j].length - 1)
      depth[j][k] = 0 if depth[j][k].nil?
      rpt_array.push(['Dtl', k, depth[j][k], len, (100.0 * depth[j][k] / len)])  ## Column entries for each coverage depth row 
    end
  end

  # print out depths over all regions combined
  rpt_array.push('H1', 'All Regions:')  ### Table Header
  rpt_array.push(['H2', 'Depth', 'Bases at depth', 'Bases in interval', 'Percent bases at depth']) ## Column Names
  
  for k in (0 .. depth[-1].length - 1)
    depth[-1][k] = 0 if depth[-1][k].nil?
    rpt_array.push(['Dtl', k, depth[-1][k], tot_len, (100.0 * depth[-1][k] / tot_len)])  ## Column entries for each coverage depth row
  end
  
  return rpt_array
end

####################################################################################################################
# print_depth:                                                                                                     #
# This method takes the depth object return by calculate_depth and the array containing bed regions (bed_array)    #
# and prints out the depth statistics.                                                                  #
####################################################################################################################
def print_depth(depth, bed_array)
  bed_sorted = bed_array.sort_by {|x| [x[0], x[1]]}
  tot_len = 0
  
  # print out depths at each region individually
  for j in (0 .. bed_sorted.length - 1)
    len = bed_sorted[j][2] - bed_sorted[j][1] + 1
    tot_len += len
    print "Region ", bed_sorted[j][0], ":", bed_sorted[j][1], "-", bed_sorted[j][2], "\n"  ### Table Header
    print ["Depth", "Bases at depth", "Bases in interval", "Percent bases at depth"].join("\t"), "\n"                                             ### Column Names
    for k in (0 .. depth[j].length - 1)
      depth[j][k] = 0 if depth[j][k].nil?
      print [k, depth[j][k], len, (100.0 * depth[j][k] / len)].join("\t"), "\n"   ### Column entries for each coverage depth row
    end
    print "\n"
  end

  # print out depths over all regions combined
  print "All regions\n";  ### Table Header
  print ["Depth", "Bases at depth", "Bases in interval", "Percent bases at depth"].join("\t"), "\n" ### Column Names
  for k in (0 .. depth[-1].length - 1)
    depth[-1][k] = 0 if depth[-1][k].nil?
    print [k, depth[-1][k], tot_len, (100.0 * depth[-1][k] / tot_len)].join("\t"), "\n" ### Column entries for each coverage depth row
  end

end

####################################################################################################################
# update_depth:                                                                                                    #
# Helper function for calculate_depth                                                                              #
####################################################################################################################
def update_depth(depth, j, curr_depth, start_pos, end_pos)
  depth[j][curr_depth] ||= 0
  depth[-1][curr_depth] ||= 0
  depth[j][curr_depth] += start_pos - end_pos
  depth[-1][curr_depth] += start_pos - end_pos
end
  
end