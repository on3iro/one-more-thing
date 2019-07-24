proc showHelp*(): void =
  echo """
omt (one more thing) is a simple CLI tool to get random strings from lists.
By default omt is looking for a configuration file called 'omt.yaml' inside
the directory the command is called.

    ##### Configuration #####

    An omt config should be written in YAML and consists of two parts:

      thingList - a list of strings where omt randomly picks values from
      pickedThings - this list could be empty (it will contain picked values in a separate save file after 'omt get' has been run at least once).


    ##### Commands #####

    omt can be called with the following commands. Appending the '-h' or '--help' flag will show more information for each respective command.

      help - shows this help
      create <projectName> - creates a directory with an empty omt.yaml config
      get - Gets a random value from the thingList and by default writes the omt_save.yaml file.
      reset - gets rid of omt_save.yaml file. Has to be called inside an omt project.
      undo - If an omt_save.yaml file exists inside the current directory <undo> will move the last picked thing back to the 'thingList'
  """
  quit()
