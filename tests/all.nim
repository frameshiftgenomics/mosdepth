import funcs

import sequtils
import unittest, mosdepth as mosdepth
import os, osproc, ospaths
import json

suite "bamstats-suite":

  setup:
    let out_folder = "tests/out"
    removeDir(out_folder)
    createDir(out_folder)

  test "basic-stats":
    let outp = execProcess("./mosdepth " & $out_folder & "/basic-stats tests/data/yeast.bam")
    echo outp

    let lsout = execProcess("ls " & $out_folder)

    let bam_stats_filename = $out_folder & "/basic-stats.mosdepth.bam_stats.json" 

    check:
      os.fileExists(bam_stats_filename)

    let expected_json = parseFile("tests/data/expected_yeast_bamstats.json")
    let observed_json = parseFile(bam_stats_filename)

    let int_keys = @[
        "both_mates_mapped", "duplicates",        "singletons",
        "failed_qc",         "first_mates",       "second_mates", 
        "mapped_reads",      "paired_end_reads",  "total_reads",
        "forward_strands",   "proper_pairs",      "reverse_strands" ]
    let unimplemented_keys = @[ "last_read_position" ]
    let hist_keys = @[ "refAln_hist", "mapq_hist" ]
    let keys = concat(int_keys, hist_keys)

    check len(keys) == len(observed_json)

    for key in int_keys:
      echo key
      check expected_json[key].getInt() == observed_json[key].getInt()

    for key in hist_keys:
      echo key
      check len(expected_json[key]) == len(observed_json[key])

    for chrom, val in observed_json["refAln_hist"]:
      check:
        expected_json["refAln_hist"].hasKey(chrom)
        expected_json["refAln_hist"][chrom].getInt() == val.getInt()
      
    for quality, count in observed_json["mapq_hist"]:
      check:
        expected_json["mapq_hist"].hasKey(quality)
        expected_json["mapq_hist"][quality].getInt() == count.getInt() 
        
        
