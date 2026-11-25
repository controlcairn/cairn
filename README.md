# cairn

`cairn` checks, generates, verifies, pushes and pulls a compliance program kept in its repository,
against [ControlCairn](https://github.com/controlcairn). This repository holds cairn's releases, the
cairn action for GitHub, Forgejo and Gitea Actions, and the cairn template for GitLab CI. Nothing
here needs a login or a token to download.

This README is cairn 0.9.1's. Your workspace's **Connect your repository** panel in ControlCairn
writes the `cairn.yaml` and the CI job for your repository, filled in; the examples below are the
same jobs, by hand.

## Install

From npm, with Node 24 or later:

```bash
npm install --global @controlcairn/cli@0.9.1
cairn login
cairn check
```

As a container image, with nothing to install:

```bash
docker run --rm --volume "$PWD:/repo" --workdir /repo ghcr.io/controlcairn/cairn:0.9.1 verify
```

As one file, with no Node: download the file for your platform from the
[cairn-v0.9.1 release](https://github.com/controlcairn/cairn/releases/tag/cairn-v0.9.1),
check it against the release's `SHA256SUMS`, and run it.

```bash
curl -fsSLO https://github.com/controlcairn/cairn/releases/download/cairn-v0.9.1/cairn-linux-x64
curl -fsSLO https://github.com/controlcairn/cairn/releases/download/cairn-v0.9.1/SHA256SUMS
sha256sum --check --ignore-missing SHA256SUMS
chmod +x cairn-linux-x64 && ./cairn-linux-x64 --help
```

The release carries `cairn-linux-x64`, `cairn-linux-arm64`, `cairn-darwin-arm64`,
`cairn-darwin-x64` and `cairn-windows-x64.exe`.

## GitHub Actions

```yaml
# .github/workflows/compliance.yml
name: compliance
on:
  push:
    branches: [main]
  pull_request:
jobs:
  cairn:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: controlcairn/cairn@cairn-v0.9.1
        with:
          image: ghcr.io/controlcairn/cairn:0.9.1
          command: check
      - if: github.event_name == 'push'
        uses: controlcairn/cairn@cairn-v0.9.1
        with:
          image: ghcr.io/controlcairn/cairn:0.9.1
          command: push
```

The job presents its own identity token to ControlCairn, which a trust rule on your workspace's CI
page admits. A job with no identity token passes the workspace's CI token as `token`, from the
repository's secrets.

## Forgejo and Gitea Actions

The same action, named by its address:

```yaml
# .forgejo/workflows/compliance.yml
name: compliance
on:
  push:
    branches: [main]
  pull_request:
jobs:
  cairn:
    runs-on: docker
    enable-openid-connect: true
    steps:
      - uses: https://data.forgejo.org/actions/checkout@v4
      - uses: https://github.com/controlcairn/cairn@cairn-v0.9.1
        with:
          image: ghcr.io/controlcairn/cairn:0.9.1
          command: check
```

## GitLab CI

The template, included from this repository at the release:

```yaml
# .gitlab-ci.yml
include:
  - remote: https://raw.githubusercontent.com/controlcairn/cairn/cairn-v0.9.1/templates/cairn.yml
    inputs:
      image: ghcr.io/controlcairn/cairn:0.9.1
      command: check
cairn-check:
  id_tokens:
    CAIRN_ID_TOKEN:
      aud: https://your-controlcairn-address
```

`aud` is the scheme and host of the `ledger.server` in your `cairn.yaml`.

## Licence

cairn is licensed under the terms in [LICENSE](LICENSE). The third-party software bundled in cairn
keeps its own licence; those notices are at the end of `bundle/cairn.cjs` in the npm package.
