META_TAGS = {description: "Stanford Human OligoGenome comprises capture oligonucleotides which cover the the human genome",
             keywords: ["stanford university, hanlee ji, george natsoulis, oligogenome, oligo genome, oligo, oligonucleotide, human genome,
                            cancer, cancer research, resequencing, dna sequencing, capture sequence, primer"]}

CAPISTRANO_DEPLOY = "#{Rails.root}".include?('releases')
ZIP_REL_PATH = (CAPISTRANO_DEPLOY ? File.join("..", "..", "shared", "files") : File.join("app/assets/files"))
ZIP_ABS_PATH = File.join("#{Rails.root}", ZIP_REL_PATH)

BED_ABS_PATH = File.join("#{Rails.root}", "app/assets/bed_files")


