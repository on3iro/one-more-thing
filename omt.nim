from random import randomize, sample
import yaml/serialization, streams

# Call randomize() once to initialize the default random number generator
# If this is not called, the same results will occur every time these
# examples are run
randomize()

type
  ConfigRoot = object
    defaultList: seq[string]

var configRoot: ConfigRoot

var stream = newFileStream("omt.yaml")

load(stream, configRoot)
stream.close()

echo sample(configRoot.defaultList)
