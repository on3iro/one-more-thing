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


#############
# Constants #
#############

const OMT_CONFIG = "omt.yaml"
const SAVE_FILE = "filtered.yaml"


##############
# Procedures #
##############

proc getThingAndRest(things: seq[Thing]): tuple[thing: Thing, rest: seq[Thing]] =
  let thing = sample(things)
  let filteredList = filter(things, proc (item: Thing): bool =
    item != thing)
  return (thing: thing, rest: filteredList)

proc retrieveOMTConfig(): ConfigRoot =
  let configStream = newFileStream(OMT_CONFIG)
  var configRoot: ConfigRoot
  load(configStream, configRoot)
  configStream.close()
  return configRoot

proc getFilteredThingsOrDefault(defaultList: seq[Thing]): seq[Thing] =
  let filteredListFileStream = newFileStream(SAVE_FILE, fmRead)
  var things: seq[Thing]
  if not(isNil(filteredListFileStream)):
    load(filteredListFileStream, things)
    filteredListFileStream.close()
    return things
  else:
    return defaultList

proc writeRestToOutputFile(rest: seq[Thing]): void =
  let filteredOutputFileStream = newFileStream(SAVE_FILE, fmWrite)
  dump(rest, filteredOutputFileStream)
  filteredOutputFileStream.close()

proc showHelp(): void =
  echo "TODO help!"

proc handleGet(optParser: var OptParser, defaultList: seq[Thing]): void =
  var
    things: seq[Thing]
    dryrun: bool = false

  while true:
    optParser.next()
    case optParser.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      case optParser.key
      of "d", "dry":
        dryrun = true
      of "s", "string":
        load(optParser.val, things)
      else:
        things = getFilteredThingsOrDefault(defaultList)
        break
    of cmdArgument:
      raise newException(IOError, "Only a single argument is allowed!")

  if things.len == 0:
    echo "List is empty!"
    quit()

  let sampleResult = getThingAndRest(things)

  if not dryrun:
    writeRestToOutputFile(sampleResult.rest)

  # Some CLI output
  echo "Default: " & defaultList
  echo "Things: " & things
  echo "Sample: " & sampleResult.thing
  echo "Filtered List: " & sampleResult.rest

  quit()

#################
# Actual Script #
#################

# Load Config #
let configRoot = retrieveOMTConfig()

# Parse arguments #

if paramCount() == 0:
  showHelp()
  quit()

var optParser = initOptParser(commandLineParams())
while true:
  optParser.next()
  case optParser.kind
  of cmdEnd: break
  of cmdShortOption, cmdLongOption:
      raise newException(IOError, "Flag [" & optParser.key & "] is not allowed in this position!")
  of cmdArgument:
    if find(commandLineParams(), optParser.key) != 0:
      raise newException(IOError, "Arguments have to directly follow the <omt> command!")
    case optParser.key
    of "create":
      echo "Argument: ", optParser.key
    of "get":
      handleGet(optParser, configRoot.defaultList)
