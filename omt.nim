from random import randomize, sample
from sequtils import filter
import yaml/serialization, streams
import parseopt
import os

# Call randomize() once to initialize the default random number generator
# If this is not called, the same results will occur every time these
# examples are run
randomize()

#########
# Types #
#########

type
  Thing = string

type
  ConfigRoot = object
    defaultList: seq[Thing]


##############
# Procedures #
##############

proc getThingAndRest(things: seq[Thing]): tuple[thing: Thing, rest: seq[Thing]] =
  let thing = sample(things)
  let filteredList = filter(things, proc (item: Thing): bool =
    item != thing)
  return (thing: thing, rest: filteredList)

proc retrieveOMTConfig(): ConfigRoot =
  let configStream = newFileStream("omt.yaml")
  var configRoot: ConfigRoot
  load(configStream, configRoot)
  configStream.close()
  return configRoot

proc getFilteredThingsOrDefault(defaultList: seq[Thing]): seq[Thing] =
  let filteredListFileStream = newFileStream("filtered.yaml", fmRead)
  var things: seq[Thing]
  if not(isNil(filteredListFileStream)):
    load(filteredListFileStream, things)
    filteredListFileStream.close()
    return things
  else:
    return defaultList

proc writeRestToOutputFile(rest: seq[Thing]): void =
  let filteredOutputFileStream = newFileStream("filtered.yaml", fmWrite)
  dump(rest, filteredOutputFileStream)
  filteredOutputFileStream.close()


#################
# Actual Script #
#################

# Parse arguments #

var params = initOptParser(commandLineParams())
while true:
  params.next()
  case params.kind
  of cmdEnd: break
  of cmdShortOption, cmdLongOption:
    if params.val == "":
      echo "Option: ", params.key
    else:
      echo "Option and Value ", params.key, ", ", params.val
  of cmdArgument:
    echo "Argument: ", params.key

# Load Config #
let configRoot = retrieveOMTConfig()

let things = getFilteredThingsOrDefault(configRoot.defaultList)
let sampleResult = getThingAndRest(things)
writeRestToOutputFile(sampleResult.rest)


# Some CLI output
echo "Default: " & configRoot.defaultList
echo "Things: " & things
echo "Sample: " & sampleResult.thing
echo "Filtered List: " & sampleResult.rest
