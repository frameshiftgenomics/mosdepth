import json
import hts
import tables

type
  bamStats* = ref object
    totalReads: int
    mappedReads: int 
    forwardStrands: int
    reverseStrands: int
    failedQC: int
    duplicates: int
    pairedEndReads: int
    properPairs: int
    bothMatesMapped: int
    firstMates: int
    secondMates: int
    singletons: int
    lastReadPos: int

    refAlnHist: CountTableRef[string]
    mapQualityHist: CountTableRef[int] 
    fragLengthHist: CountTableRef[int]
    readLengthHist: CountTableRef[int]

proc countRead*(rs: var bamStats, rec: Record, chrom: string = nil) = 
  rs.totalReads += 1
  if rec.flag.proper_pair:
    rs.properPairs += 1

  if rec.flag.dup: rs.duplicates += 1
  if rec.flag.qcfail: rs.failedQC += 1
  if not rec.flag.unmapped: rs.mappedReads += 1

  if rec.flag.reverse: rs.reverseStrands += 1
  else: rs.forwardStrands += 1

  if hts.pair(rec.flag):
    rs.pairedEndReads += 1
    
    if rec.flag.read1: rs.firstMates += 1
    if rec.flag.read2: rs.secondMates += 1

    if not rec.flag.unmapped: 
      if rec.flag.mate_unmapped: rs.singletons += 1
      else: rs.bothMatesMapped += 1
  
  if chrom != nil:
    rs.refAlnHist.inc(chrom)
    #if not rs.refAlnHist.hasKey(chrom):
    #  rs.refAlnHist[chrom] = 0
    #rs.refAlnHist[chrom] += 1
  
  rs.mapQualityHist.inc((int)rec.mapping_quality)
  rs.readLengthHist.inc(rec.b.core.l_qseq)

  # This field is dubious as it depends on the order of traversing the bam file
  rs.lastReadPos = rec.start

  if hts.pair(rec.flag) and not rec.flag.unmapped and not rec.flag.mate_unmapped and rec.chrom == rec.mate_chrom and rec.mate_pos > rec.start:
    rs.fragLengthHist.inc(rec.isize)
   

proc init*(rs: var bamStats) = 

  if rs == nil:
    rs = new(bamStats)

  rs.totalReads = 0

  rs.mappedReads = 0
  rs.bothMatesMapped = 0
  rs.pairedEndReads = 0
  rs.properPairs = 0

  rs.firstMates = 0
  rs.secondMates = 0
  
  rs.forwardStrands = 0
  rs.reverseStrands = 0
  
  rs.duplicates = 0
  rs.singletons = 0
  
  rs.lastReadPos = 0
  rs.failedQC = 0

  rs.refAlnHist = newCountTable[string]()
  rs.mapQualityHist = newCountTable[int]()
  rs.fragLengthHist = newCountTable[int]()
  rs.readLengthHist = newCountTable[int]()

proc to_json*(rs: bamStats): string = 
  let js = %* {
    "total_reads" : rs.totalReads,

    "mapped_reads" : rs.mappedReads,
    "both_mates_mapped" : rs.bothMatesMapped,
    "paired_end_reads" : rs.pairedEndReads,
    "proper_pairs" : rs.properPairs,
    
    "first_mates" : rs.firstMates,
    "second_mates" : rs.secondMates,

    "forward_strands" : rs.forwardStrands,
    "reverse_strands" : rs.reverseStrands,

    "duplicates" : rs.duplicates,
    "singletons" : rs.singletons,

    # "last_read_position" : rs.lastReadPos,
    "failed_qc" : rs.failedQC, 
    "refAln_hist" : %*{},
    "mapq_hist" : %*{},
    "frag_hist" : %*{},
    "length_hist" : %*{},

  }

  for chrom, count in rs.refAlnHist.pairs():
    js["refAln_hist"].add(chrom, newJInt(count))
  
  for quality, count in rs.mapQualityHist.pairs():
    js["mapq_hist"].add($quality, newJInt(count))

  for length, count in rs.fragLengthHist.pairs():
    js["frag_hist"].add($length, newJInt(count))

  for length, count in rs.readLengthHist.pairs():
    js["length_hist"].add($length, newJInt(count))

  return js.pretty()
    