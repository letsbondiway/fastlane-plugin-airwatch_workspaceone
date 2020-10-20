# airwatch_workspaceone plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-airwatch_workspaceone)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-airwatch_workspaceone`, add it to your project by running:

```bash
bundle exec fastlane add_plugin airwatch_workspaceone
```

## About airwatch_workspaceone

The main purpose of this plugin is to upload an IPA or an APK file to an AirWatch or Workspace ONE enterprise instance/console. For Android, the plugin works only with legacy AirWatch console and not with Workspace ONE console.

This plugin features following actions :-
1. deploy_build - The main purpose of this action is to upload an IPA or an APK file to an AirWatch or Workspace ONE enterprise console.
2. retire_previous_versions - The main purpose of this action is to retire previous active versions of an application. This action takes a string parameter where you can specify the number of latest versions to keep if you do not want to retire all the previous active versions.
3. delete_previous_versions - The main purpose of this action is to delete versions of an application. This action takes a string parameter where you can specify the number of latest versions to keep if you do not want to delete all the versions.
4. retire_specific_version - The main purpose of this action is to retire a specific version of an application. This action takes a string parameter where you can specify the version number to retire.
5. delete_specific_version - The main purpose of this action is to delete a specific version of an application. This action takes a string parameter where you can specify the version number to delete.
6. add_or_update_assignments - The main purpose of this action is to add a new smart group assignment to an application or to update an existing smart group assignment of an application with a given dictionary of deployment/assignment parameters. If a smart group name is provided which does not exist yet on Console, assignment for that smart group is ignored.
7. unretire_all_versions - The main purpose of this action is to unretire all retired versions of an application.
8. unretire_specific_version - The main purpose of this action is to unretire a specific version of an application. This action takes a string parameter where you can specify the version number to unretire.
9. latest_version - The main purpose of this action is to find the version number of the latest version of the app on the console and output the same. It also finds and outputs arrays of active app version numbers and retired app version numbers of the app.

## Available options

To check for available options, run

```bash
bundle exec fastlane action deploy_build
```
```bash
bundle exec fastlane action retire_previous_versions
```
```bash
bundle exec fastlane action delete_previous_versions
```
```bash
bundle exec fastlane action retire_specific_version
```
```bash
bundle exec fastlane action delete_specific_version
```
```bash
bundle exec fastlane action add_or_update_assignments
```
```bash
bundle exec fastlane action unretire_all_versions
```
```bash
bundle exec fastlane action unretire_specific_version
```
```bash
bundle exec fastlane action latest_version
```
Please do not append /API/ at the end of host_url option in any of the actions; you should pass something like - https://asxxx.awmdm.com. Thanks to [Willie Stewart](https://github.com/wstewartii) for facing an [issue](https://github.com/letsbondiway/fastlane-plugin-airwatch_workspaceone/issues/2) because of this due to which this gets documented.
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
