from random import randomize
import parseopt
import yaml/serialization, streams
import colorize

from helpers import
  retrieveOMTConfigFromFile,
  retrieveOMTConfig,
  getSavedConfigOrDefault,
  getThingAndRest,
  upateSaveFile
import types
import constants


###########
# Helpers #
###########

proc showHelpAndQuit() =
  echo "\nomt".fgBlue & " get".fgGreen
  echo """

Gets a random value from a 'thingList' either by using a local configuraition or a provided file/string.
  """

  echo "\t-d".fgMagenta & ", " & "--dry".fgMagenta
  echo "\t\tRuns the command as dryrun not writing an output save file"
  echo "\n"

  echo "\t-s".fgMagenta & "=<yamlFormedListString>, " & "--string".fgMagenta & "=<yamlFormedListString>"
  echo "\t\tUses the provided list string instead of a config file."
  echo "\t\tCareful: This might still overwrite an existing omt_save.yaml if you do not run the command as dryrun (see [-d])!"
  echo "\t\tExample:"
  echo "\t\t\tomt get -s=\"['a', 'b', 'c']\""
  echo "\n"

  echo "\t-o".fgMagenta & "=<nameOfOutputFile>, " & "--output".fgMagenta & "=<nameOfOutputFile>"
  echo "\t\tSaves the configuration to the specified outputfile instead of omt_save.yaml"
  echo "\n"
  quit()

proc getConfigFromFile(path: string): ThingList =
  try:
    let things = retrieveOMTConfigFromFile(path).thingList
    if len(things) == 0:
      raise newException(IOError, "The specified file does not contain a <thingList> or it is empty!")
    else:
      return things
  except:
    echo "File is no valid omt configuration!"
    echo getCurrentException().name
    echo getCurrentExceptionMsg()
    quit()

proc getListFromString(yamlString: string): ThingList =
  var things: ThingList
  load(yamlString, things)
  return things

###############
# Main export #
###############

proc handleGet*(optParser: var OptParser): void =
  # Call randomize() once to initialize the default random number generator
  # If this is not called, the same results will occur every time these
  # examples are run
  randomize()

  var
    things: ThingList
    dryrun: bool = false
    outputPath: string = SAVE_FILE
    configRoot: ConfigRoot

  while true:
    optParser.next()
    case optParser.kind
    of cmdShortOption, cmdLongOption:
      case optParser.key
      of "h", "help":
        showHelpAndQuit()
      of "d", "dry":
        dryrun = true
      of "s", "string":
        things = getListFromString(optParser.val)
      of "f", "file":
        things = getConfigFromFile(optParser.val)
      of "o", "output":
        outputPath = optParser.val
      else:
        # just ignore unwanted flags
        discard
    of cmdArgument:
      raise newException(IOError, "Only a single argument is allowed!")
    of cmdEnd:
      break

  # Try to get valid config from files
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

  # Exit because no valid config could be found
  if things.len == 0:
    echo "List is empty!"
    quit()
  else:
    let sampleResult = getThingAndRest(things)

    if not dryrun:
      upateSaveFile(sampleResult.rest, configRoot, sampleResult.thing, outputPath)

    echo "Here's your thing: " & sampleResult.thing

    quit()
