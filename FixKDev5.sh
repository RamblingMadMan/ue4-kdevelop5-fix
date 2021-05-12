#!/bin/bash

# Change to match UE4 root directory
UE4DIR="$HOME/UE4/UnrealEngine"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

PROJECT_NAME=$(basename "$SCRIPT_DIR")

# Replace wrong project source locations

INCLUDES="${SCRIPT_DIR}/Intermediate/Build/Linux/B4D820EA/UE4Editor/Inc/$PROJECT_NAME"

NEWINCLUDES=$(
	cat "$SCRIPT_DIR/.kdev4/Includes.txt" |
	sed -e "s,$UE4DIR/Source/$PROJECT_NAME,$SCRIPT_DIR/Source/$PROJECT_NAME,g"
)

NEWINCLUDES="${NEWINCLUDES}\n${INCLUDES}"

# Add UBT/UHT defines

DEFINES="UBT_COMPILED_PLATFORM=Linux\n${PROJECT_NAME^^}_API= \n"

NEWDEFINES=$(cat "$SCRIPT_DIR/.kdev4/Defines.txt")
NEWDEFINES="${NEWDEFINES}\n${DEFINES}"

# Write new includes

echo -e "${NEWINCLUDES}" > "$SCRIPT_DIR/.kdev_include_paths"
#echo -e "${NEWINCLUDES}" > "$SCRIPT_DIR/.kdev4/NewIncludes.txt"

# Replace wrong executable locations

NEWPROJECTFILE=$(
	cat "$SCRIPT_DIR/.kdev4/$PROJECT_NAME.kdev4" |
	sed -e "s,Executable=make,Executable=file:///usr/bin/make,g" |
	sed -e "s,Executable=bash,Executable=file:///usr/bin/bash,g" |
	sed -e "s,Executable=Engine,Executable=file://$UE4DIR/Engine,g" |
	sed -e "s,Arguments=Engine,Arguments=$UE4DIR/Engine,g"
)

mv "$SCRIPT_DIR/.kdev4/$PROJECT_NAME.kdev4" "$SCRIPT_DIR/.kdev4/$PROJECT_NAME.kdev4.bak"

echo -e "${NEWPROJECTFILE}" > "$SCRIPT_DIR/.kdev4/$PROJECT_NAME.kdev4"

echo -e "\n[CustomDefinesAndIncludes][ProjectPath0][Defines]${NEWDEFINES}" >> "$SCRIPT_DIR/.kdev4/$PROJECT_NAME.kdev4"

#echo -e "${NEWDEFINES}" > "$SCRIPT_DIR/.kdev4/NewDefines.txt"
