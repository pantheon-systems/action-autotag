# Autotag action
[![Unofficial Support](https://img.shields.io/badge/Pantheon-Unofficial_Support-yellow?logo=pantheon&color=FFDC28)](https://docs.pantheon.io/oss-support-levels#unofficial-support)
[![Autotag and Release](https://github.com/pantheon-systems/action-autotag/actions/workflows/tag-release.yml/badge.svg)](https://github.com/pantheon-systems/action-autotag/actions/workflows/tag-release.yml)
[![MIT License](https://img.shields.io/github/license/pantheon-systems/action-autotag)](https://github.com/pantheon-systems/action-autotag/blob/main/LICENSE) 
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/pantheon-systems/action-autotag)](https://github.com/pantheon-systems/action-autotag/releases)

A GitHub action that implements [autotag-dev/autotag](https://github.com/autotag-dev/autotag).

## What's it do?
This action will automatically create a new tag and release for your repository when a pull request is merged to the default branch. It will also create a changelog entry for the new tag and release.

The action pins a specific version of the autotag binary with SHA-256 checksum verification. A [scheduled workflow](.github/workflows/check-autotag-version.yml) checks for new upstream releases weekly and opens a PR when one is available.

## Inputs

<!-- AUTO-DOC-INPUT:START - Do not remove or modify this section -->

|           INPUT           |  TYPE  | REQUIRED |  DEFAULT  |                                     DESCRIPTION                                      |
|---------------------------|--------|----------|-----------|--------------------------------------------------------------------------------------|
|      create-release       | string |  false   | `"true"`  | Whether to create a release from <br>the tag or not. 'true', 'false', <br>'draft'.   |
| push-major-version-branch | string |  false   | `"false"` | Push to a branch matching the <br>major version number on the origin <br>repository  |
|         push-tag          | string |  false   | `"true"`  |                      Push the tag to the origin <br>repository                       |
|         v-prefix          | string |  false   | `"true"`  |                 Whether to prefix the tag with <br>the letter 'v'.                   |
|          workdir          | string |  false   |   `"."`   |                            Directory with the code to tag                            |

<!-- AUTO-DOC-INPUT:END -->

## Outputs

<!-- AUTO-DOC-OUTPUT:START - Do not remove or modify this section -->

| OUTPUT |  TYPE  |       DESCRIPTION        |
|--------|--------|--------------------------|
|  tag   | string | The tag that was created |

<!-- AUTO-DOC-OUTPUT:END -->

### Updating the pinned autotag version

The autotag binary version and SHA-256 checksum are defined in `action.yml` (env vars `AUTOTAG_VERSION` and `AUTOTAG_SHA256`). The version is also tracked in `dependencies.yml` for automated update detection.

When a new version is available, the scheduled workflow opens a PR bumping `dependencies.yml`. To complete the update:

1. Update `AUTOTAG_VERSION` in `action.yml` to the new version
2. Fetch the new checksum:
   ```sh
   VERSION=v1.4.3  # replace with new version
   curl -sL "https://github.com/autotag-dev/autotag/releases/download/${VERSION}/autotag_${VERSION#v}_checksums.txt" \
     | grep 'autotag_linux_amd64$'
   ```
3. Update `AUTOTAG_SHA256` in `action.yml` with the hash from step 2

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
        with:
          fetch-depth: 0
      - uses: pantheon-systems/action-autotag@v1
```
