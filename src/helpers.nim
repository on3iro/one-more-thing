from random import sample
import yaml/serialization, streams
from sequtils import filter

import constants
from types import Thing, ThingList, ConfigRoot

###########
# Helpers #
###########

proc getThingAndRest*(things: seq[Thing]): tuple[thing: Thing, rest: seq[Thing]] =
  let thing = sample(things)
  let filteredList = filter(things, proc (item: Thing): bool =
    item != thing)
  return (thing: thing, rest: filteredList)

proc createOMTConfig*(
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

proc retrieveOMTConfigFromFile*(path: string): ConfigRoot =
  let configStream = newFileStream(path)
  var configRoot: ConfigRoot
  load(configStream, configRoot)
  configStream.close()
  return configRoot

proc retrieveOMTConfig*(): ConfigRoot = retrieveOMTConfigFromFile(OMT_CONFIG)

proc writeSaveFile*(config: ConfigRoot, outputPath: string = SAVE_FILE) =
  try:
    createOMTConfig(things = config.thingList, pickedThings = config.pickedThings, outputPath = outputPath)
  except:
    echo "Could not write save file!"
    echo getCurrentException().name
    echo getCurrentExceptionMsg()
    quit()


proc getSavedConfigOrDefault*(defaultConfig: ConfigRoot, filePath: string = SAVE_FILE): ConfigRoot =
  try:
    let savedConfig = retrieveOMTConfigFromFile(filePath)
    return savedConfig
  except:
    return defaultConfig

proc upateSaveFile*(
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
