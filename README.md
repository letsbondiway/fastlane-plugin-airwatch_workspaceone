# airwatch_workspaceone plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-airwatch_workspaceone)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-airwatch_workspaceone`, add it to your project by running:

```bash
fastlane add_plugin airwatch_workspaceone
```

## About airwatch_workspaceone

The main purpose of this plugin is to upload an IPA or an APK file to an AirWatch or Workspace ONE enterprise instance/console.

This plugin features two actions :-
1. deploy_build - To upload an iOS ipa OR Android APK to AirWatch/WorkspaceOne console.
2. retire_previous_versions - To retire all active versions of the application on the AirWatch console except the latest version.

## Available options

To check for available options, run

```bash
fastlane action deploy_app
```
and 

```bash
fastlane action retire_previous_versions
```

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin.

## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
