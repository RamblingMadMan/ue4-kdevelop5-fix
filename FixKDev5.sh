#!/bin/bash

SKIP_GENERATE=0

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
	-s|--skip-generate)
	shift
	;;
	*)
	>&2 echo "Usage: [UE4DIR=/path/to/UnrealEngine] ./FixKDev5.sh [-s|--skip-generate]"
	exit 1
	shift
	;;
esac
done
set -- "${POSITIONAL[@]}"

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

PROJECT_INCLUDE_DIRS="
${SCRIPT_DIR}/Intermediate/Build/Linux/B4D820EA/UE4Editor/Inc/$PROJECT_NAME
${SCRIPT_DIR}/Source/$PROJECT_NAME
${SCRIPT_DIR}/Source/$PROJECT_NAME/Public
"

UE4_INCLUDE_DIRS=$(
	cat "$SCRIPT_DIR/.kdev4/Includes.txt" |
	sed -e "s,$UE4DIR/Source/$PROJECT_NAME,$SCRIPT_DIR/Source/$PROJECT_NAME,g"
)

NEWKDEV4INCLUDES=""

IFS=$'\n'
counter=0
for line in $PROJECT_INCLUDE_DIRS
do
	counter=$(( $counter + 1 ))
	NEWKDEV4INCLUDES="${NEWKDEV4INCLUDES}\n$counter=$line"
done

# Add UBT/UHT defines

echo "-- Fixing Generated Defines"

DEFINES="
IS_PROGRAM=0
UE_EDITOR=1
ENABLE_PGO_PROFILE=0
UNICODE
_UNICODE
__UNREAL__
IS_MONOLITHIC=0
WITH_ENGINE=1
WITH_UNREAL_DEVELOPER_TOOLS=1
WITH_APPLICATION_CORE=1
WITH_COREUOBJECT=1
WITH_ENGINE=1
UBT_COMPILED_PLATFORM=Linux
UBT_COMPILED_TARGET=Editor
UE_APP_NAME=\"UE4Editor\"
PLATFORM_LINUX=1
PLATFORM_UNIX=1
LINUX=1
PLATFORM_SUPPORTS_JEMALLOC=1
OVERRIDE_PLATFORM_HEADER_NAME=Linux
PLATFORM_LINUXAARCH64=0
UE_BUILD_DEVELOPMENT=1
UE_IS_ENGINE_MODULE=0
UE_PROJECT_NAME=${PROJECT_NAME^}
IMPLEMENT_ENCRYPTION_KEY_REGISTRATION()=
IMPLEMENT_SIGNING_KEY_REGISTRATION()=
DEPRECATED_FORGAME=DEPRECATED
UE_DEPRECATED_FORGAME=UE_DEPRECATED
${PROJECT_NAME^^}_VTABLE=DLLEXPORT_VTABLE
${PROJECT_NAME^^}_API=
"

PUBLIC_API_NAMES="
ENGINE
CORE
TRACELOG
COREUOBJECT
NETCORE
APPLICATIONCORE
RHI
JSON
SLATECORE
INPUTCORE
SLATE
IMAGEWRAPPER
MESSAGING
MESSAGINGCOMMON
RENDERCORE
SOCKETS
ASSETREGISTRY
ENGINEMESSAGES
ENGINESETTINGS
SYNTHBENCHMARK
RENDERER
GAMEPLAYTAGS
PACKETHANDLER
RELIABILITYHANDLERCOMPONENT
AUDIOPLATFORMCONFIGURATION
MESHDESCRIPTION
STATICMESHDESCRIPTION
PAKFILE
RSA
NETWORKREPLAYSTREAMING
PHYSICSCORE
CHAOS
CHAOSCORE
VORONOI
FIELDSYSTEMCORE
SIGNALPROCESSING
UNREALED
BSPMODE
DIRECTORYWATCHER
DOCUMENTATION
PROJECTS
SANDBOXFILE
EDITORSTYLE
SOURCECONTROL
UNREALEDMESSAGES
GAMEPLAYDEBUGGER
BLUEPRINTGRAPH
EDITORSUBSYSTEM
HTTP
UNREALAUDIO
FUNCTIONALTESTING
AUTOMATIONCONTROLLER
LOCALIZATION
AUDIOEDITOR
AUDIOMIXER
TARGETPLATFORM
UELIBSAMPLERATE
LEVELEDITOR
SETTINGS
INTROTUTORIALS
HEADMOUNTEDDISPLAY
VREDITOR
COMMONMENUEXTENSIONS
LANDSCAPE
PROPERTYEDITOR
ACTORPICKERMODE
SCENEDEPTHPICKERMODE
DETAILCUSTOMIZATIONS
CLASSVIEWER
GRAPHEDITOR
STRUCTVIEWER
CONTENTBROWSER
NETWORKFILESYSTEM
UMG
MOVIESCENE
TIMEMANAGEMENT
MOVIESCENETRACKS
ANIMATIONCORE
PROPERTYPATH
NAVIGATIONSYSTEM
MESHDESCRIPTIONOPERATIONS
MESHBUILDER
MATERIALSHADERQUALITYSETTINGS
INTERACTIVETOOLSFRAMEWORK
TOOLMENUSEDITOR
ASSETTAGSEDITOR
COLLECTIONMANAGER
ADDCONTENTDIALOG
MESHUTILITIES
MESHMERGEUTILITIES
HIERARCHICALLODUTILITIES
MESHREDUCTIONINTERFACE
ASSETTOOLS
KISMETCOMPILER
GAMEPLAYTASKS
AIMODULE
KISMET
PHYSICSSQ
CHAOSSOLVERS
GEOMETRYCOLLECTIONCORE
GEOMETRYCOLLECTIONSIMULATIONCORE
CLOTHINGSYSTEMRUNTIMEINTERFACE
AUDIOMIXERCORE
GAMEPLAYABILITIES
"

for name in $PUBLIC_API_NAMES
do
	DEFINES="${DEFINES}${name}_VTABLE=DLLIMPORT_VTABLE\n${name}_API=\n"
done

NEWDEFINES=$(cat "$SCRIPT_DIR/.kdev4/Defines.txt")
NEWDEFINES="${DEFINES}${NEWDEFINES}"

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
)

# Set standard to C++17

NEWPROJECTFILE="${NEWPROJECTFILE}\n\n[CustomDefinesAndIncludes][ProjectPath0]
Path=.
parseAmbiguousAsCPP=true
parserArguments=-ferror-limit=100 -Wdocumentation -Wunused-parameter -Wunreachable-code -Wall -std=c++17
parserArgumentsC=-ferror-limit=100 -Wdocumentation -Wunused-parameter -Wunreachable-code -Wall -std=c99
parserArgumentsCuda=-ferror-limit=100 -Wdocumentation -Wunused-parameter -Wunreachable-code -Wall -std=c++11
parserArgumentsOpenCL=-ferror-limit=100 -Wdocumentation -Wunused-parameter -Wunreachable-code -Wall -cl-std=CL1.1"

# Update defines

NEWPROJECTFILE="${NEWPROJECTFILE}\n\n[CustomDefinesAndIncludes][ProjectPath0][Defines]${NEWDEFINES}"

# Update includes

echo -e "${UE4_INCLUDE_DIRS}" > ${SCRIPT_DIR}/.kdev_include_paths

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
