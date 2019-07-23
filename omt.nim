from random import randomize, sample
from sequtils import filter
import yaml/serialization, streams
import parseopt
import os

#[
  TODO
  * Save list of picked things to save file
  * interactive get
  * interactive create
  * undo
  * help
]#

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
    thingList: seq[Thing]


#############
# Constants #
#############

const OMT_CONFIG = "omt.yaml"
const SAVE_FILE = "omt_save.yaml"


###########
# Helpers #
###########

proc getThingAndRest(things: seq[Thing]): tuple[thing: Thing, rest: seq[Thing]] =
  let thing = sample(things)
  let filteredList = filter(things, proc (item: Thing): bool =
    item != thing)
  return (thing: thing, rest: filteredList)

proc createOMTConfig(things: seq[Thing], outputPath: string): void =
  let configFileOutputStream = newFileStream(outputPath, fmWrite)
  dump(ConfigRoot(thingList: things), configFileOutputStream)
  configFileOutputStream.close()

proc retrieveOMTConfigFromFile(path: string): ConfigRoot =
  let configStream = newFileStream(path)
  var configRoot: ConfigRoot
  load(configStream, configRoot)
  configStream.close()
  return configRoot

proc retrieveOMTConfig(): ConfigRoot = retrieveOMTConfigFromFile(OMT_CONFIG)

proc getSavedThingsOrDefault(defaultList: seq[Thing], filePath: string = SAVE_FILE): seq[Thing] =
  try:
    let filteredConfig = retrieveOMTConfigFromFile(filePath)
    return filteredConfig.thingList
  except:
    return defaultList

proc writeRestToOutputFile(rest: seq[Thing], outputPath: string = SAVE_FILE): void = createOMTConfig(rest, outputPath)


################
# CLI Handlers #
################

proc resetSave(): void =
  echo "Removing save file: " & SAVE_FILE & "..."
  removeFile(SAVE_FILE)

proc showHelp(): void =
  # TODO
  echo "TODO help!"
  quit()

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

  createOMTConfig(@[], joinPath(projectPath, OMT_CONFIG))

proc handleGet(optParser: var OptParser): void =
  var
    things: seq[Thing]
    dryrun: bool = false
    outputPath: string = SAVE_FILE

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
        try:
          things = retrieveOMTConfigFromFile(optParser.val).thingList
          if len(things) == 0:
            raise newException(IOError, "The specified file does not contain a <thingList> or it is empty!")
        except:
          echo "File is no valid omt configuration!"
          echo getCurrentException().name
          echo getCurrentExceptionMsg()
          quit()
      of "o", "output":
        try:
          outputPath = optParser.val
        except:
          echo "Output file is invalid!"
          echo getCurrentException().name
          echo getCurrentExceptionMsg()
          quit()
      else:
        # just ignore unwanted flags
        discard
    of cmdArgument:
      raise newException(IOError, "Only a single argument is allowed!")
    of cmdEnd:
      if len(things) == 0:
        try:
          # Load Config #
          let configRoot = retrieveOMTConfig()

          let thingList = configRoot.thingList
          things = getSavedThingsOrDefault(thingList)
        except:
          echo "Could not find valid configuration!\n" &
            "Either use <" & OMT_CONFIG & ">, <" & SAVE_FILE & "> or provide string via '-s=<string>'!\n"
          echo getCurrentException().name
          echo getCurrentExceptionMsg()
          quit()
      break


  if things.len == 0:
    echo "List is empty!"
    quit()

  let sampleResult = getThingAndRest(things)

  if not dryrun:
    writeRestToOutputFile(sampleResult.rest, outputPath)

  echo "Here's your thing: " & sampleResult.thing

  quit()


########
# MAIN #
########

proc main(): void =
  if paramCount() == 0:
    showHelp()

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
      of "create":
        createOMTProject(optParser)
      of "get":
        handleGet(optParser)
      of "reset":
        resetSave()

main()
