from os import joinPath
# Package

version       = "0.0.1"
author        = "creatable"
description   = "A simple GooseMod installer."
license       = "Unlicense"
srcDir        = "src"
bin           = @["Mallard"]


# Dependencies

requires "nim >= 1.4.2"

task debug, "makes a debug build":
    exec("nim c -d:debug --out:bin/debug/" & bin[0] & " --app:gui " & joinPath(srcDir, bin[0]) & ".nim")

task release, "Makes a release build":
    exec("nim c --opt:size -d:release --out:bin/release/" & bin[0] & " --app:gui " & joinPath(srcDir, bin[0]) & ".nim")

task macrelease, "Cross-compiles a release build for Mac OS":
    exec("nim c --os:macosx --opt:size -d:release --out:bin/release/osx/" & bin[0] & " --app:gui " & joinPath(srcDir, bin[0]) & ".nim")