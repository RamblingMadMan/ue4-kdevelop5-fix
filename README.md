# UE4 KDevelop5 Fix

I've been cobbling this little bash script together for issues I've had with Unreal Engine 4 using KDevelop5 on Linux.

This script should set everything up (KDevelop project files, semantic highlighting and autocompletion) so you can simply code, build and run.

Tested with Unreal Engine 4.26.2 on KDE Neon 20.04

Also check out the `.gitignore` file in this repo for a good base for your own Projects.

## Prerequisites

You must have already [compiled Unreal Engine](https://docs.unrealengine.com/en-US/SharingAndReleasing/Linux/BeginnerLinuxDeveloper/SettingUpAnUnrealWorkflow/index.html) and created a project.

### Dependencies

A single dependency is required for parsing the Unreal project file.

- jq

## Usage

> You may want to add `FixKDev5.sh` and `*/.kdev_include_paths` to your projects `.gitignore` file.

Copy `FixKDev5.sh` to the root directory of your project then run it like so:

```bash
./FixKDev5.sh [-s|--skip-generate]
```

The `-s` or `--skip-generate` argument can be passed to save a little time if you are sure the project has been generated since you last added any files.

The script will try to find your copy of UnrealEngine 4 by searching in `~/.local/share/applications` for a file called `com.epicgames.UnrealEngineEditor.desktop`.
If this file can not be found then the script will fallback to searching in these directories:
- `~/UnrealEngine`
- `~/Epic/UnrealEngine/`
- `~/EpicGames/UnrealEngine/`
- `~/Epic Games/UnrealEngine`

If the script fails to find your build, you can specify it by setting the environment variable `UE4DIR`.

As an example, if I had compiled UE4 under another folder `~/UE4` and the script couldn't find it:

```bash
UE4DIR=~/UE4/UnrealEngine ./FixKDev5.sh -s
```

# Optional

## Faster KDevelop project loading

To load projects a *lot* faster disable entire project parsing:

![KDevelop project settings](https://raw.githubusercontent.com/RamblingMadMan/ue4-kdevelop5-fix/media/kdevelop_project_options.png)

## UnrealBuildTool configuration

Whenever the editor re-generates a project (i.e. every time you create a new C++ class) it generates a lot of useless data for other IDE's. These extra steps can take a while and make the whole process feel a lot more sluggish, but you can configure the UnrealBuildTool to skip all the project types you don't care about.

To do this you can modify `.config/Unreal Engine/UnrealBuildTool/BuildConfiguration.xml` so that it contains the following `<ProjectFileGenerator>` section:

```xml
<?xml version="1.0" encoding="utf-8" ?>
<Configuration xmlns="https://www.unrealengine.com/BuildConfiguration">
	<ProjectFileGenerator>
			<Format>KDevelop</Format>
	</ProjectFileGenerator>
</Configuration>
```

To do this for an unmodified `BuildConfiguration.xml` run this command:

```bash
sed -i 's,<Configuration xmlns="https://www.unrealengine.com/BuildConfiguration">,<Configuration xmlns="https://www.unrealengine.com/BuildConfiguration">\n\t<ProjectFileGenerator>\n\t\t<Format>KDevelop</Format>\n\t</ProjectFileGenerator>,' ~/.config/Unreal\ Engine/UnrealBuildTool/BuildConfiguration.xml
```

## Environment variables

If you have to use `UE4DIR=...` every time you run the script, append this line to your `~/.bashrc`:

```bash
export UE4DIR=/path/to/UnrealEngine
```

This can be done with this command:

```bash
echo "export UE4DIR=/path/to/UnrealEngine" >> ~/.bashrc
```

Once this is set either log out and back in or run `. ~/.bashrc`.

Now you can run the script from any project by running:

```bash
./FixKDev5.sh [-s]
```
