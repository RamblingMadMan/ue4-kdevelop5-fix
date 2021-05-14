#!/bin/bash

if [ -z "$UE4DIR" ]; then
	UE4DIR="$HOME/UnrealEngine"
fi

SCRIPT_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"

PROJECT_NAME=$(basename "$SCRIPT_DIR")

PROJECT_FILE="$SCRIPT_DIR/$PROJECT_NAME.uproject"

if [ ! -f "$PROJECT_FILE" ]; then
	>&2 echo "[ERROR] Put this script in your Unreal Engine Project folder."
	exit 1
fi

if [ ! -f "$UE4DIR/GenerateProjectFiles.sh" ]; then
	>&2 echo "[ERROR] Set UE4DIR or symlink your UnrealEngine 4 root dir to ~/UnrealEngine"
	exit 1
fi

echo "-- Generating UE4 Project"

$UE4DIR/GenerateProjectFiles.sh -kdevelopfile -project="${PROJECT_FILE}" -game -engine -editor

# Replace wrong project source locations

echo "-- Fixing Generated Includes"

INCLUDES="${SCRIPT_DIR}/Intermediate/Build/Linux/B4D820EA/UE4Editor/Inc/$PROJECT_NAME"

NEWINCLUDES=$(
	cat "$SCRIPT_DIR/.kdev4/Includes.txt" |
	sed -e "s,$UE4DIR/Source/$PROJECT_NAME,$SCRIPT_DIR/Source/$PROJECT_NAME,g"
)

NEWINCLUDES="${NEWINCLUDES}"$'\n'"${INCLUDES}"

NEWKDEV4INCLUDES=""

IFS=$'\n'
counter=0
for line in $NEWINCLUDES
do
	counter=$(( $counter + 1 ))
	NEWKDEV4INCLUDES="$NEWKDEV4INCLUDES\n$counter=$line"
done

# Add UBT/UHT defines

echo "-- Fixing Generated Defines"

DEFINES="UBT_COMPILED_PLATFORM=Linux\n${PROJECT_NAME^^}_API= \n"

NEWDEFINES=$(cat "$SCRIPT_DIR/.kdev4/Defines.txt")
NEWDEFINES="${NEWDEFINES}\n${DEFINES}"

# Replace wrong executable locations

echo "-- Fixing Generated KDevelop Project"

# Get editor configuration number
EDITORCONFIG=$(
	cat "$SCRIPT_DIR/.kdev4/$PROJECT_NAME.kdev4" |
	grep -x -B 2 "Title=techtatorshipEditor" 2>&1 | head -n 1 |
	sed 's/[^0-9]*//g'
)

NEWPROJECTFILE=$(
	cat "$SCRIPT_DIR/.kdev4/$PROJECT_NAME.kdev4" |
	sed -e "s,Executable=make,Executable=file:///usr/bin/make,g" |
	sed -e "s,Executable=bash,Executable=file:///usr/bin/bash,g" |
	sed -e "s,Executable=Engine,Executable=file://$UE4DIR/Engine,g" |
	sed -e "s,Arguments=Engine,Arguments=$UE4DIR/Engine,g" |
	sed -e "s,CurrentConfiguration=BuildConfig0,CurrentConfiguration=BuildConfig$EDITORCONFIG," # Set editor as current config
	# Add includes to project file
	#sed -e "s,[CustomDefinesAndIncludes][ProjectPath0][Includes],[CustomDefinesAndIncludes][ProjectPath0][Includes]${NEWKDEV4INCLUDES},"
)

# Set standard to C++17

NEWPROJECTFILE="${NEWPROJECTFILE}\n\n[CustomDefinesAndIncludes][ProjectPath0]
Path=.
parseAmbiguousAsCPP=true
parserArguments=-ferror-limit=100 -fspell-checking -Wdocumentation -Wunused-parameter -Wunreachable-code -Wall -std=c++17
parserArgumentsC=-ferror-limit=100 -fspell-checking -Wdocumentation -Wunused-parameter -Wunreachable-code -Wall -std=c99
parserArgumentsCuda=-ferror-limit=100 -fspell-checking -Wdocumentation -Wunused-parameter -Wunreachable-code -Wall -std=c++11
parserArgumentsOpenCL=-ferror-limit=100 -fspell-checking -Wdocumentation -Wunused-parameter -Wunreachable-code -Wall -cl-std=CL1.1"

# Update defines

NEWPROJECTFILE="${NEWPROJECTFILE}\n\n[CustomDefinesAndIncludes][ProjectPath0][Defines]${NEWDEFINES}"

# Update includes

NEWPROJECTFILE="${NEWPROJECTFILE}\n\n[CustomDefinesAndIncludes][ProjectPath0][Includes]${NEWKDEV4INCLUDES}"

# Create editor launch command

NEWPROJECTFILE="${NEWPROJECTFILE}\n
[Launch]
Launch Configurations=Launch Configuration 0

[Launch][Launch Configuration 0]
Configured Launch Modes=execute
Configured Launchers=nativeAppLauncher
Name=Editor
Type=Native Application

[Launch][Launch Configuration 0][Data]
Arguments=\"$PROJECT_FILE\"
Dependencies=@Variant(\x00\x00\x00\t\x00\x00\x00\x00\x00)
Dependency Action=Nothing
EnvironmentGroup=
Executable=file://$UE4DIR/Engine/Binaries/Linux/UE4Editor
External Terminal=konsole --noclose --workdir %workdir -e %exe
Kill Before Executing Again=4194304
Project Target=
Use External Terminal=false
Working Directory=file://$UE4DIR/Engine/Binaries/Linux
isExecutable=true"

# Create backup of old project file

echo "-- Writing changes to disk"

mv "$SCRIPT_DIR/.kdev4/$PROJECT_NAME.kdev4" "$SCRIPT_DIR/.kdev4/$PROJECT_NAME.kdev4.bak"

# Write new project file to disk

echo -e "${NEWPROJECTFILE}" > "$SCRIPT_DIR/.kdev4/$PROJECT_NAME.kdev4"

echo "-- Done"
