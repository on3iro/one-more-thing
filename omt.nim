from random import randomize, sample
from sequtils import filter
import yaml/serialization, streams
import parseopt
import os

from types import Thing, ThingList, ConfigRoot

#[
  TODO
  * Refactor
  * interactive get
  * interactive create
  * interactive undo
  * json support
  * ASCI support
]#

# Call randomize() once to initialize the default random number generator
# If this is not called, the same results will occur every time these
# examples are run
randomize()


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

proc createOMTConfig(
  things: ThingList,
  pickedThings: ThingList,
  outputPath: string
): void =
  let configFileOutputStream = newFileStream(outputPath, fmWrite)
  dump(
    ConfigRoot(thingList: things, pickedThings: pickedThings),
    configFileOutputStream
  )
  configFileOutputStream.close()

proc retrieveOMTConfigFromFile(path: string): ConfigRoot =
  let configStream = newFileStream(path)
  var configRoot: ConfigRoot
  load(configStream, configRoot)
  configStream.close()
  return configRoot

proc retrieveOMTConfig(): ConfigRoot = retrieveOMTConfigFromFile(OMT_CONFIG)

proc writeSaveFile(config: ConfigRoot, outputPath: string = SAVE_FILE) =
  try:
    createOMTConfig(things = config.thingList, pickedThings = config.pickedThings, outputPath = outputPath)
  except:
    echo "Could not write save file!"
    echo getCurrentException().name
    echo getCurrentExceptionMsg()
    quit()


proc getSavedConfigOrDefault(defaultConfig: ConfigRoot, filePath: string = SAVE_FILE): ConfigRoot =
  try:
    let savedConfig = retrieveOMTConfigFromFile(filePath)
    return savedConfig
  except:
    return defaultConfig

proc upateSaveFile(
  rest: seq[Thing],
  defaultConfig: ConfigRoot,
  pickedThing: string,
  outputPath: string = SAVE_FILE
): void =
  try:
    let savedConfig = getSavedConfigOrDefault(defaultConfig, outputPath)
    let pickedThings = savedConfig.pickedThings & pickedThing
    createOMTConfig(things = rest, pickedThings = pickedThings, outputPath = outputPath)
  except:
    echo "Could not write save file!"
    echo getCurrentException().name
    echo getCurrentExceptionMsg()
    quit()


################
# CLI Handlers #
################

proc resetSave(): void =
  echo "Removing save file: " & SAVE_FILE & "..."
  removeFile(SAVE_FILE)

proc showHelp(): void =
  echo """
omt (one more thing) is a simple CLI tool to get random strings from lists.
By default omt is looking for a configuration file called 'omt.yaml' inside
the directory the command is called.

    ##### Configuration #####

    An omt config should be written in YAML and consists of two parts:

      thingList - a list of strings where omt randomly picks values from
      pickedThings - this list could be empty (it will contain picked values in a separate save file after 'omt get' has been run at least once).


    ##### Commands #####

    omt can be called with the following commands. Appending the '-h' or '--help' flag will show more information for each respective command.

      help - shows this help
      create <projectName> - creates a directory with an empty omt.yaml config
      get - Gets a random value from the thingList and by default writes the omt_save.yaml file.
      reset - gets rid of omt_save.yaml file. Has to be called inside an omt project.
      undo - If an omt_save.yaml file exists inside the current directory <undo> will move the last picked thing back to the 'thingList'
  """
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
      of "h", "help":
        echo """
omt create <projectName>
  
  Creates a directory by the specified project name and a default
  omt.yaml configuration.
        """
        quit()
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

  createOMTConfig(
    things = cast[ThingList](@[]),
    pickedThings = cast[ThingList](@[]),
    outputPath = joinPath(projectPath, OMT_CONFIG)
  )

proc handleUndo(optParser: var OptParser) =
  var saveFilePath: string = SAVE_FILE

  while true:
    optParser.next()
    case optParser.kind
    of cmdArgument:
      discard
    of cmdShortOption, cmdLongOption:
      case optParser.key
      of "h", "help":
        echo """
omt undo

  Moves the last item from the <pickedThings> list of an omt configuration back to its <thingsList>.

  -f=<fileName>, --file=<fileName>
      Uses the specified YAML file instead of the default 'omt_save.yaml'.
        """
        quit()
      of "f", "file":
        saveFilePath = optParser.val
      else:
        discard
    of cmdEnd:
      break

  try:
    let saveConfig = retrieveOMTConfigFromFile(saveFilePath)
    var pickedThings = saveConfig.pickedThings
    let thingList: seq[Thing] = saveConfig.thingList
    let thingToUndo: Thing = pop(pickedThings)
    let updatedThingList = thingList & thingToUndo

    echo "Thing <" & thingToUndo & "> will be undone!"
    echo "Writing save file..."
    writeSaveFile(ConfigRoot(thingList: updatedThingList, pickedThings: pickedThings), outputPath = saveFilePath)
  except:
    echo "Could not undo!"
    echo getCurrentException().name
    echo getCurrentExceptionMsg()
    quit()

proc handleGet(optParser: var OptParser): void =
  var
    things: seq[Thing]
    dryrun: bool = false
    outputPath: string = SAVE_FILE
    configRoot: ConfigRoot

  while true:
    optParser.next()
    case optParser.kind
    of cmdShortOption, cmdLongOption:
      case optParser.key
      of "h", "help":
        echo """
omt get [flags]

  Gets a random value from a 'thingList' either by using a local configuraition or a provided file/string.

  -d, --dry
    Runs the command as dryrun not writing an output save file

  -s=<yamlFormedListString>, --string=<yamlFormedListString>
    Uses the provided list string instead of a config file.
    Careful: This might still overwrite an existing omt_save.yaml if you
    do not run the command as dryrun (see [-d])!

    Example:
      omt get -s="['a', 'b', 'c']"

  -o=<nameOfOutputFile>, --output=<nameOfOutputFile>
    Saves the configuration to the specified outputfile instead of omt_save.yaml
        """
        quit()
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
          configRoot = retrieveOMTConfig()
          things = getSavedConfigOrDefault(configRoot).thingList
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
    upateSaveFile(sampleResult.rest, configRoot, sampleResult.thing, outputPath)

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
      of "undo":
        handleUndo(optParser)

main()
