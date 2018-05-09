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

    let lsout = execProcess("ls " & $out_folder)

    let bam_stats_filename = $out_folder & "/basic-stats.mosdepth.bam_stats.json" 

    check:
      os.fileExists(bam_stats_filename)

    let expected_json = parseFile("tests/data/expected_yeast_bamstats.json")
    let observed_json = parseFile(bam_stats_filename)

    let int_keys = @["total_reads"]
    let keys = concat(int_keys)

    check: len(keys) == len(observed_json)
    for key in int_keys:
      check expected_json[key].getInt() == observed_json[key].getInt()
