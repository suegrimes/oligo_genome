META_TAGS = {:description => "Stanford Human OligoGenome comprises capture oligonucleotides which cover the the human genome",
             :keywords => ["stanford university, hanlee ji, george natsoulis, oligogenome, oligo genome, oligo, oligonucleotide, human genome,
                            cancer, cancer research, resequencing, dna sequencing, capture sequence, primer"]}

CAPISTRANO_DEPLOY = RAILS_ROOT.include?('releases')
FILES_ROOT = (CAPISTRANO_DEPLOY == true ? File.join(RAILS_ROOT, "..", "..", "shared", "files") :
                                          File.join(RAILS_ROOT, "public", "files"))
