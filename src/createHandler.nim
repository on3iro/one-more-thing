import os
import parseopt
import colorize

import types
from helpers import createOMTConfig
import constants


###########
# Helpers #
###########

proc showHelpAndQuit() =
  echo "\nomt".fgLightBlue & " create".fgGreen & " <projectName>"

  echo """

Creates a directory by the specified project name and a default
omt.yaml configuration.
  """
  quit()

###########
# Handler #
###########

proc createOMTProject*(optParser: var OptParser): void =
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
        showHelpAndQuit()
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

  quit()
