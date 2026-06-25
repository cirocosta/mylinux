# Contributing

This repo keeps machine setup in `provision.sh`. Changes should stay small,
repeatable, and easy to verify on a fresh Ubuntu VM.

## Provisioning Patterns

- Add one `install_<tool>` function per tool.
- Add version and checksum constants near the top of `provision.sh`.
- Pin upstream release artifacts by version and SHA256.
- Prefer official upstream binaries when apt is stale or lacks the tool.
- Use apt for ordinary OS packages and prerequisites.
- Keep target names explicit in `run_target`; add aliases only when common.
- Add new default tools to `provision_all`.
- Keep installs idempotent. Detect the desired version and return early.
- Use `mktemp` or `mktemp -d`; clean temporary files before returning.
- Install standalone tools into `/usr/local/bin`.
- Install tool trees under `/usr/local/<tool>` and symlink commands into
  `/usr/local/bin`.
- Support `amd64` and `arm64` when upstream publishes both.
- Fail clearly for unsupported architectures.
- Avoid interactive commands in `provision.sh`.

## Acceptance

For each new provisioned tool:

- `./provision.sh <target>` installs it on a fresh Ubuntu VM.
- Running the same target again reports the installed version or exits cleanly.
- `./provision.sh all` includes the tool when it belongs in the default set.
- Downloads come from official release locations.
- Checksums are pinned in the script.
- Installed command checks are added to `test-multipass.sh`.
- `./provision.sh help` lists the new target.
- `bash -n provision.sh` passes.
- `bash -n test-multipass.sh` passes.

For shell config or dotfile changes:

- Use `write_file_if_changed` for fully managed files.
- Use `ensure_line` or `ensure_symlink` when preserving user-owned files.
- Add VM assertions for expected files, lines, and symlinks.

## Testing

Fast local checks:

```sh
bash -n provision.sh
bash -n test-multipass.sh
./provision.sh help
git diff --check
```

Full VM test:

```sh
./test-multipass.sh
```

The Multipass test creates a disposable Ubuntu VM, copies `provision.sh`, runs
the full provisioning flow twice, and checks installed tools and config files.
By default it deletes any existing VM with the same name before launching:

```text
VM_NAME=mylinux-provision-test
```

Use a custom VM name when you want to avoid touching another test run:

```sh
VM_NAME=mylinux-provision-test-node ./test-multipass.sh
```

Keep the VM for debugging:

```sh
KEEP_VM=1 ./test-multipass.sh
```

Useful knobs:

```text
IMAGE=<host Ubuntu VERSION_ID>
CPUS=2
MEMORY=4G
DISK=20G
```

When a VM test fails, rerun with `KEEP_VM=1`, inspect with `multipass shell`,
then delete it when done:

```sh
multipass delete <vm-name> --purge
```
