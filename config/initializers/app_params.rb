META_TAGS = {:description => "Stanford Human OligoGenome comprises capture oligonucleotides which cover the the human genome",
             :keywords => ["stanford university, hanlee ji, george natsoulis, oligogenome, oligo genome, oligo, oligonucleotide, human genome,
                            cancer, cancer research, resequencing, dna sequencing, capture sequence, primer"]}

CAPISTRANO_DEPLOY = RAILS_ROOT.include?('releases')
REL_PATH_TO_FILES = (CAPISTRANO_DEPLOY ? File.join("..", "..", "shared", "files") : File.join("..", "OligoFiles", "files"))
FULL_PATH_TO_FILES = File.join(RAILS_ROOT, REL_PATH_TO_FILES)