#!/bin/bash

if ! command -v jq &> /dev/null
then
	echo "[ERROR] Could not find 'jq'"
	echo "    Install it with your package manager"
	exit
fi

SKIP_GENERATE=0

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
	-s|--skip-generate)
	SKIP_GENERATE=1
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

PROJECT_DIR=${SCRIPT_DIR}

FOLDER_NAME=$(basename "$PROJECT_DIR")

PROJECT_NAME=$(ls "${PROJECT_DIR}" | grep ".uproject" | sed "s,.uproject,,")

PROJECT_FILE="$PROJECT_DIR/$PROJECT_NAME.uproject"

if [ ! -f "$PROJECT_FILE" ]; then
	>&2 echo "[ERROR] Put this script in your Unreal Engine Project folder."
	exit 1
fi

if [ ! -f "$UE4DIR/GenerateProjectFiles.sh" ]; then
	>&2 echo "[ERROR] Set UE4DIR or symlink your UnrealEngine 4 root dir to ~/UnrealEngine"
	exit 1
fi

echo "-- Generating UE4 Project"

if [ "$SKIP_GENERATE" -eq "0" ]; then
	$UE4DIR/GenerateProjectFiles.sh -kdevelopfile -project="${PROJECT_FILE}" -game -engine -editor
fi

DEPENDENCIES_JSON=$(cat "${PROJECT_NAME}.uproject" | jq ".Modules[0].AdditionalDependencies")
DEPENDENCIES_JSON_LINES=$(echo "${DEPENDENCIES_JSON}" | wc -l)
NUM_DEPENDENCIES=$(( $DEPENDENCIES_JSON_LINES - 2 ))
DEPENDENCIES=$(echo "${DEPENDENCIES_JSON}" | head -n -1 | tail -n ${NUM_DEPENDENCIES} | sed -E "s,[ \t]+\"([A-Za-z0-9_]+)\"[,]?,\1,g" )

echo "-- Found $NUM_DEPENDENCIES dependencies"

# Replace wrong project source locations

echo "-- Fixing Generated Includes"

PROJECT_INCLUDE_DIRS="
${PROJECT_DIR}/Intermediate/Build/Linux/B4D820EA/UE4Editor/Inc/$PROJECT_NAME
${PROJECT_DIR}/Source/$PROJECT_NAME
${PROJECT_DIR}/Source/$PROJECT_NAME/Public"

UE4_INCLUDE_DIRS=$(
	cat "$PROJECT_DIR/.kdev4/Includes.txt" |
	sed -e "s,$UE4DIR/Source/$PROJECT_NAME,$PROJECT_DIR/Source/$PROJECT_NAME,g"
)

IFS=$'\n'

for dep in $DEPENDENCIES
do
	PLUGIN_PROJECT_DIR=$(find Plugins -name "${dep}.uplugin")
	
	if [ ! -z "${PLUGIN_PROJECT_DIR}" ]; then
		PLUGIN_PROJECT_DIR=$(dirname ${PLUGIN_PROJECT_DIR})
		
		echo "    Found project plugin '${dep}' at '${PLUGIN_PROJECT_DIR}'"
		
		PROJECT_INCLUDE_DIRS="${PROJECT_INCLUDE_DIRS}
${PROJECT_DIR}/${PLUGIN_PROJECT_DIR}/Source/${dep}
${PROJECT_DIR}/${PLUGIN_PROJECT_DIR}/Source/${dep}/Public
${PROJECT_DIR}/${PLUGIN_PROJECT_DIR}/Intermediate/Build/Linux/B4D820EA/UE4Editor/Inc/${dep}"

# 		UE4_INCLUDE_DIRS=$(sed -E "s,${UE4DIR}/Engine/Plugins/${PLUGIN_PROJECT_NAME}/,${PROJECT_DIR}/Plugins/${PLUGIN_PROJECT_NAME}}/,g")
	else
		echo "    Found engine plugin '${dep}'"
	fi
done

NEWKDEV4INCLUDES=""

counter=0
for line in $PROJECT_INCLUDE_DIRS
do
	if [ -d "${line}" ]; then
		counter=$(( $counter + 1 ))
		NEWKDEV4INCLUDES="${NEWKDEV4INCLUDES}\n$counter=$line"
	else
		echo " Non-existant include directory: '${line}'"
	fi
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
AIMODULE
KISMET
PHYSICSSQ
CHAOSSOLVERS
GEOMETRYCOLLECTIONCORE
GEOMETRYCOLLECTIONSIMULATIONCORE
CLOTHINGSYSTEMRUNTIMEINTERFACE
AUDIOMIXERCORE
"

for dep in $DEPENDENCIES
do
	PUBLIC_API_NAMES="${PUBLIC_API_NAMES}${dep^^}
"
done

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

mv "$PROJECT_DIR/$PROJECT_NAME.kdev4" "$PROJECT_DIR/$FOLDER_NAME.kdev4"
mv "$PROJECT_DIR/.kdev4/$PROJECT_NAME.kdev4" "$PROJECT_DIR/.kdev4/$PROJECT_NAME.kdev4.bak"

# Write new project file to disk

echo -e "${NEWPROJECTFILE}" > "$PROJECT_DIR/.kdev4/$FOLDER_NAME.kdev4"

echo "-- Done"
