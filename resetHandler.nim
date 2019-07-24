import os

import constants

proc resetSave*(): void =
  echo "Removing save file: " & SAVE_FILE & "..."
  removeFile(SAVE_FILE)
