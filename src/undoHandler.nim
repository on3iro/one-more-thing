import os
import parseopt
import yaml/serialization, streams

import types
import helpers
import constants

proc handleUndo*(optParser: var OptParser) =
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
