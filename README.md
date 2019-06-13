# airwatch_workspaceone plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-airwatch_workspaceone)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-airwatch_workspaceone`, add it to your project by running:

```bash
fastlane add_plugin airwatch_workspaceone
```

## About airwatch_workspaceone

The main purpose of this plugin is to upload an IPA or an APK file to an AirWatch or Workspace ONE enterprise instance/console. For Android, the plugin works only with legacy AirWatch console and not with Workspace ONE console.

This plugin features following actions :-
1. deploy_build - To upload an iOS ipa to both legacy AirWatch and Workspace ONE console. Also, to upload an Android APK to legacy AirWatch console.
2. retire_previous_versions - The main purpose of this action is to retire previous active versions of an application. This action takes a string parameter where you can specify the number of latest versions to keep if you do not want to retire all the previous active versions.
3. delete_previous_versions - The main purpose of this action is to delete versions of an application. This action takes a string parameter where you can specify the number of latest versions to keep if you do not want to delete all the versions.
4. retire_specific_version - The main purpose of this action is to retire a specific version of an application. This action takes a string parameter where you can specify the version number to retire.
5. delete_specific_version - The main purpose of this action is to delete a specific version of an application. This action takes a string parameter where you can specify the version number to delete.
6. add_or_update_assignments_action - The main purpose of this action is to add a new smart group assignment to an application or to update an existing smart group assignment of an application with a given dictionary of deployment/assignment parameters. If a smart group name is provided which does not exist yet on Console, assignment for that smart group is ignored.
7. unretire_all_versions - The main purpose of this action is to unretire all retired versions of an application.

## Available options

To check for available options, run

```bash
fastlane action deploy_build
```
```bash
fastlane action retire_previous_versions
```
```bash
fastlane action delete_previous_versions
```
```bash
fastlane action retire_specific_version
```
```bash
fastlane action delete_specific_version
```
```bash
fastlane action add_or_update_assignments
```
```bash
fastlane action unretire_all_versions
```

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see example lanes.

To make use of this plugin, run one of the lanes using the following command -

```bash
bundle exec fastlane lane_name
```
If you are using .env files (please find sample - .env.development at the same folder where Fastfile is located), please specify using --env parameter

```bash
bundle exec fastlane lane_name --env development
```

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
