# Autotag action
[![Unofficial Support](https://img.shields.io/badge/Pantheon-Unofficial_Support-yellow?logo=pantheon&color=FFDC28)](https://docs.pantheon.io/oss-support-levels#unofficial-support)
[![Lint](https://github.com/pantheon-systems/action-autotag/actions/workflows/lint.yml/badge.svg)](https://github.com/pantheon-systems/action-autotag/actions/workflows/lint.yml)
[![Autotag and Release](https://github.com/pantheon-systems/action-autotag/actions/workflows/tag-release.yml/badge.svg)](https://github.com/pantheon-systems/action-autotag/actions/workflows/tag-release.yml)
[![MIT License](https://img.shields.io/github/license/pantheon-systems/action-autotag)](https://github.com/pantheon-systems/action-autotag/blob/main/LICENSE) 
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/pantheon-systems/action-autotag)](https://github.com/pantheon-systems/action-autotag/releases)

A GitHub action that implements [pantheon-systems/autotag](https://github.com/pantheon-systems/autotag).

## What's it do?
This action will automatically create a new tag and release for your repository when a pull request is merged to the default branch. It will also create a changelog entry for the new tag and release.

Currently configuration is limited (see [source](https://github.com/pantheon-systems/action-autotag/blob/main/src/tag-release.sh)), but in future iterations more configuration options will be added.

This action is currently experimental.

## Inputs

### `gh-token`
A GitHub token with `repo` scope. This is used to create the tag and release.

### Usage
```yaml
name: Autotag and Release
on:
  push:
    branches:
      - main

permissions:
  contents: write

jobs:
  tag-release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pantheon-systems/action-autotag@v0
        with:
          gh-token: ${{ github.token }}
```