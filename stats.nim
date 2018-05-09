import json

type
  readStats* = ref object
    totalReads*: int
    mappedReads*: int 
    forwardStrands*: int
    reverseStrands*: int
    failedQC*: int
    duplicates*: int
    pairedEndReads*: int
    properPairs*: int
    bothMatesMapped*: int
    firstMates*: int
    secondMates*: int
    singletons*: int
    lastReadPos*: int

proc init*(rs: var readStats) = 

  if rs == nil:
    rs = new(readStats)

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

proc to_json*(rs: readStats): string = 
  let js = %* {
    "total_reads" : rs.totalReads
  }

  return js.pretty()
    