import parseopt
import os

import 
  src/createHandler,
  src/getHandler,
  src/helpHandler,
  src/resetHandler,
  src/undoHandler

#[
  TODO
  * Refactor
  * interactive get
  * interactive create
  * interactive undo
  * json support
  * ASCI support
]#



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
