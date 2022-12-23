# Symbolicator

Symbolicator is a tool for manually de-obfuscating and symbolicating crash reports in textual formats in the case that other services fail to provide this feature. It is mostly designed to be used when crash reports have `hidden#` marks in them (bitcode obfuscation), otherwise Xcode can be used to symbolicate reports (note that this tool can symbolicate reports that are not obfuscated, as well.)

To use it, locate the Xcode archive which you wish to use (i.e. the one for the app you are working with - be sure the build is correct) and the crash report file.

The default format for using Symbolicator is:
> `./Symbolicator <.xcarchive for build> <crash log file>`

Type `./Symbolicator` and drag the archive into the terminal (to automagically insert its filepath). Do the same with the crash report file. Run the program and wait for it to complete, where a updated crash report file will be exported to the current working directory (with filename `symbolicated.crash`.)

#### Options

The following options can be provided to Symbolicator. You may provide options in any order. For example, you could place the options before the base arguments, or they could be placed after the base arguments.

##### `-n`/`--no-archive`

If you don't have the archive but do have the `BCSymbolMaps` and `dSYMs` folders, you can use the `-n` or `--no-archive` option to provide the folders directly. The format for this is
> `./Symbolicator -n <BCSymbolMaps folder> <dSYMs folder> <crash report file>`

##### `-o`/`--output`

You can specify your own output filename with `-o` or `--output`. For example:
> `./Symbolicator <.xcarchive for build> <crash log file> -o myFile.crash`

Note that using this with `-m`/`--multi` does nothing, as that option uses the original report name for the output.

##### `-m`/`--multi`

With `-m`, you can make Symbolicator iterate over all crash reports in a directory. An example of using this command for reports in the current directory is:
> `./Symbolicator <.xcarchive for build> -m .`

## Help

### I'm getting a "permission denied" error when trying to run Symbolicator

These tools need to be marked as executable before they will run. Use `chmod +x <tool>` to give `<tool>` the permissions it requires to execute.

### I can't run the Symbolicator executable on macOS Catalina because the developer is unverified

Run the app by locating it in Finder and double-clicking it. This will prompt you to open the app despite it being unverified and save the choice made, enabling use in the terminal. If this doesn't work, try looking in your System Preferences to see if you can allow access from there.
