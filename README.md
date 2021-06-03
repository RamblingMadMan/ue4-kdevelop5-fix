# UE4 KDevelop5 Fix

Fix for Unreal Engine 4 projects with KDevelop5 on Linux.

This script should set everything up (including semantic highlighting and autocompletion) so you can simply code, build and run.

Tested with Unreal Engine 4.26.2 on KDE Neon 20.04

Also check out the `.gitignore` file in this repo for a good base for your own Projects.

## Prerequisites

You must have already [compiled Unreal Engine](https://docs.unrealengine.com/en-US/SharingAndReleasing/Linux/BeginnerLinuxDeveloper/SettingUpAnUnrealWorkflow/index.html) and created a project with the editor.

### Dependencies

A single dependency is required for parsing the Unreal project file.

- jq

## Usage

> You may want to add `FixKDev5.sh` to your projects `.gitignore` file.

Copy `FixKDev5.sh` to the root directory of your project and launch the script with the following format:

```bash
UE4DIR=/path/to/UnrealEngine ./FixKDev5.sh [-s|--skip-generate]
```

The `-s` or `--skip-generate` argument can be passed to save a little time if you are sure the project has been generated since you last ran the script.

If `UE4DIR` is not set the script will search in `~/UnrealEngine` by default.

As an example if I had compiled UE4 under another folder named 'UE4' and created a new project:

```bash
UE4DIR=~/UE4/UnrealEngine ./FixKDev5.sh -s
```
