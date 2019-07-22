from random import randomize, sample
from sequtils import filter
import yaml/serialization, streams

# Call randomize() once to initialize the default random number generator
# If this is not called, the same results will occur every time these
# examples are run
randomize()

type
  ConfigRoot = object
    defaultList: seq[string]

# Load Config #

let configStream = newFileStream("omt.yaml")
var configRoot: ConfigRoot
load(configStream, configRoot)
configStream.close()

let thing = sample(configRoot.defaultList)
let filteredList = filter(configRoot.defaultList, proc (item: string): bool =
  item != thing)

echo "Default: " & configRoot.defaultList
echo "Sample: " & thing
echo "Filtered List: " & filteredList

let filteredListOutputStream = newFileStream("filtered.yaml", fmWrite)
dump(filteredList, filteredListOutputStream)
filteredListOutputStream.close()

