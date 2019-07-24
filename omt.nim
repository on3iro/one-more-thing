from random import randomize, sample
from sequtils import filter
import yaml/serialization, streams
import parseopt
import os

from types import Thing, ThingList, ConfigRoot
import createHandler, getHandler, helpHandler, resetHandler, undoHandler

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
