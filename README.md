# NOVA RUSH — Rift Runner

A lightweight 2D neon survival runner made with Godot 4.3+. The prototype uses procedural drawing, so it has no external art or audio dependencies.

## Play
- Open `project.godot` in Godot 4.3 or newer.
- Press F6/F5 to run.
- Desktop: Left/Right arrows or A/D to switch lanes; Space to dash.
- Android: use the left/right and dash buttons, or swipe left/right.

## Gameplay
- Dodge blocks, mines and laser gates.
- Collect energy shards for bonus score.
- Shield and magnet pickups provide temporary abilities.
- Speed and spawn rate increase over time.
- Best score is saved locally on the device.

## Android export
Install the matching Godot export templates and configure Android SDK/JDK in Editor Settings. Create an Android export preset named exactly `Android`, then export a debug APK. The GitHub workflow below can run a headless export after you add a valid `export_presets.cfg` and configure the Android SDK environment/secrets for your chosen build runner.

This is a playable first prototype, not yet a production release. Online leaderboards, accounts, analytics, cloud saves, sound, accessibility and store compliance are future milestones.
