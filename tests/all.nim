import funcs

import sequtils
import unittest, mosdepth as mosdepth
import os, osproc, ospaths
import json

suite "bamstats-suite":
  # TODO: Replace the s3 root and aws profile with Frameshift values
  let s3_root_key = "oconnorinformaticseast1/data/"
  putEnv("AWS_PROFILE", "admin")

  let out_folder = "tests/out"
  removeDir(out_folder)
  createDir(out_folder)

  proc test_basic_stats(flags: string, prefix: string, alignment_file: string, expected_json: string) = 
    let outp = execProcess("./mosdepth " & $flags & " " & $out_folder & "/" & $prefix & " " & alignment_file)
    #echo outp

    let lsout = execProcess("ls " & $out_folder)

    let bam_stats_filename = $out_folder & "/" & $prefix & ".mosdepth.bam_stats.json" 

    check:
      os.fileExists(bam_stats_filename)

    let expected_json = parseFile(expected_json)
    let observed_json = parseFile(bam_stats_filename)

    let int_keys = @[
        "both_mates_mapped", "duplicates",        "singletons",
        "failed_qc",         "first_mates",       "second_mates", 
        "mapped_reads",      "paired_end_reads",  "total_reads",
        "forward_strands",   "proper_pairs",      "reverse_strands" ]
    let unimplemented_keys = @[ "last_read_position" ]
    let hist_keys = @[ "refAln_hist", "mapq_hist", "frag_hist", "length_hist" ]
    let keys = concat(int_keys, hist_keys)

    check len(keys) == len(observed_json)

    for key in int_keys:
      #echo key
      check expected_json[key].getInt() == observed_json[key].getInt()

    for key in hist_keys:
      #echo key
      check len(expected_json[key]) == len(observed_json[key])

    for chrom, val in observed_json["refAln_hist"]:
      check:
        expected_json["refAln_hist"].hasKey(chrom)
        expected_json["refAln_hist"][chrom].getInt() == val.getInt()
      
    for quality, count in observed_json["mapq_hist"]:
      check:
        expected_json["mapq_hist"].hasKey(quality)
        expected_json["mapq_hist"][quality].getInt() == count.getInt() 

    var frag_count = 0
    for length, count in observed_json["frag_hist"]: frag_count += count.getInt()   

    var expected_frag_count = 0
    for length, count in expected_json["frag_hist"]: expected_frag_count += count.getInt()   

    check expected_frag_count == frag_count

    for length, count in observed_json["frag_hist"]:
      check:
        expected_json["frag_hist"].hasKey(length)
        expected_json["frag_hist"][length].getInt() == count.getInt()
    
    for length, count in observed_json["length_hist"]:
      check:
        expected_json["length_hist"].hasKey(length)
        expected_json["length_hist"][length].getInt() == count.getInt()

  test "bam-basic-stats":
    test_basic_stats(
      "", 
      "bam-basic-stats", 
      "tests/data/yeast.bam", 
      "tests/data/expected_yeast_bamstats.json")
        
  test "cram-basic-stats":
    # The expected CRAM stats have a manufactured length_hist field where are reads are counted at zero length
    # because the hts cram parser does not populate the length field
    test_basic_stats(
      "-f tests/data/yeast.fasta.gz", 
      "cram-basic-stats", 
      "tests/data/yeast.cram", 
      "tests/data/expected_yeast_cramstats.json")
   
  test "bam-basic-stats-s3":
    test_basic_stats(
      "", 
      "bam-basic-stats-s3", 
      "s3://" & s3_root_key & "yeast.bam", 
      "tests/data/expected_yeast_bamstats.json")
          
  test "cram-basic-stats-s3":
    # The expected CRAM stats have a manufactured length_hist field where are reads are counted at zero length
    # because the hts cram parser does not populate the length field
    test_basic_stats(
      "-f tests/data/yeast.fasta.gz", 
      "cram-basic-stats-s3", 
      "s3://" & s3_root_key & "yeast.cram", 
      "tests/data/expected_yeast_cramstats.json") 
