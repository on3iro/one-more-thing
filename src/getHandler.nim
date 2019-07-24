from random import randomize
import parseopt
import yaml/serialization, streams

from helpers import
  retrieveOMTConfigFromFile,
  retrieveOMTConfig,
  getSavedConfigOrDefault,
  getThingAndRest,
  upateSaveFile
import types
import constants

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
