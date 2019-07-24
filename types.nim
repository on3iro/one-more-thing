#########
# Types #
#########

type
  Thing* = string

type
  ThingList* = seq[Thing]

type
  ConfigRoot* = object
    thingList*: ThingList
    pickedThings*: ThingList
