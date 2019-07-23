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

proc resetRest(): void =
  # TODO
  echo "TODO: implement!"

proc showHelp(): void =
  # TODO
  echo "TODO help!"

proc createOMTProject(optParser: var OptParser): void =
  var projectPath: string = ""

  while true:
    optParser.next()
    case optParser.kind
    of cmdArgument:
      if len(projectPath) == 0:
        projectPath = optParser.key
      else:
        discard
    of cmdShortOption, cmdLongOption:
      case optParser.key
      # There are currently no options for this command!
      else:
        discard
    of cmdEnd:
      break

  if len(projectPath) == 0:
    raise newException(IOError, "No project path given! Please specify a project path!")

  let dirExists = existsOrCreateDir(projectPath)

  if dirExists:
    echo "Project already exists!"
    quit()

  echo "Creating project..."

  let configFileOutputStream = newFileStream(joinPath(projectPath, OMT_CONFIG), fmWrite)
  dump(ConfigRoot(defaultList: @[]), configFileOutputStream)
  configFileOutputStream.close()

proc handleGet(optParser: var OptParser): void =
  var
    things: seq[Thing]
    dryrun: bool = false

  while true:
    optParser.next()
    case optParser.kind
    of cmdShortOption, cmdLongOption:
      case optParser.key
      of "d", "dry":
        dryrun = true
      of "s", "string":
        load(optParser.val, things)
      of "f", "file":
        echo "TODO: implement --file flag!"
      of "o", "output":
        echo "TODO: implement --output flag!"
      else:
        # just ignore unwanted flags
        break
    of cmdArgument:
      raise newException(IOError, "Only a single argument is allowed!")
    of cmdEnd:
      if len(things) == 0:
        try:
          # Load Config #
          let configRoot = retrieveOMTConfig()

          let defaultList = configRoot.defaultList
          things = getFilteredThingsOrDefault(defaultList)

        except:
          echo "Could not find valid configuration!\n" &
            "Either use <" & OMT_CONFIG & ">, <" & SAVE_FILE & "> or provide string via '-s=<string>'!\n"
          quit()
      break


  if things.len == 0:
    echo "List is empty!"
    quit()

  let sampleResult = getThingAndRest(things)

  if not dryrun:
    writeRestToOutputFile(sampleResult.rest)

  echo "Here's your thing: " & sampleResult.thing

  quit()


#################
# Actual Script #
#################

proc main(): void =
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
      of "help":
        showHelp()
        quit()
      of "create":
        createOMTProject(optParser)
      of "get":
        handleGet(optParser)
      of "reset":
        resetRest()

main()
