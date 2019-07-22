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

type
  Thing = string

# Load Config #

let configStream = newFileStream("omt.yaml")
var configRoot: ConfigRoot
load(configStream, configRoot)
configStream.close()

# Open output file #
let filteredListFileStream = newFileStream("filtered.yaml", fmRead)

# Get thing list #

var things: seq[Thing]
if not(isNil(filteredListFileStream)):
  load(filteredListFileStream, things)
  filteredListFileStream.close()
else:
  things = configRoot.defaultList

# Get Sample #

let thing = sample(things)
let filteredList = filter(things, proc (item: string): bool =
  item != thing)

# Generate output file #

let filteredOutputFileStream = newFileStream("filtered.yaml", fmWrite)
dump(filteredList, filteredOutputFileStream)
filteredOutputFileStream.close()

# Some CLI output

echo "Default: " & configRoot.defaultList
echo "Things: " & things
echo "Sample: " & thing
echo "Filtered List: " & filteredList

