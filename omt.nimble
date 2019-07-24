# Package

version       = "1.0.1"
author        = "Theo Salzmann"
description   = "omt - CLI Tool to randomly retrieve list items and keep the rest"
license       = "MIT"
srcDir        = "src"
bin           = @["omt"]



# Dependencies

requires "nim >= 0.20.2"
requires "colorize >= 0.2.0"
requires "yaml"
