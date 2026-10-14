#!/bin/bash
# Reproduce the production Metal + capture + UI tests on an installed iOS 18
# simulator. No runtime downloads, simulator creation, or dependency installation.
#
#   ./scripts/test-ios18.sh
#   SIMULATOR_UDID=<existing-ios18-udid> ARTIFACT_DIR=/absolute/new/run-dir \
#     ./scripts/test-ios18.sh
#
# ARTIFACT_DIR must be absent or empty. Otherwise the default is a unique directory
# under .build/ios18-validation. The existing generated project is backed up before
# XcodeGen regenerates it; source files and the simulator's data are not reset.
set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    sed -n '2,/^set -/ { /^set -/d; s/^# \{0,1\}//; p; }' "${BASH_SOURCE[0]}"
    exit 0
fi
if [[ $# -ne 0 ]]; then
    printf 'error: expected no arguments; use SIMULATOR_UDID and ARTIFACT_DIR environment variables.\n' >&2
    exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EXAMPLE_DIR="$REPO_ROOT/Example"
PROJECT="$EXAMPLE_DIR/LiquidGlassDemo.xcodeproj"

for dependency in xcrun xcodebuild python3; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        printf 'error: required command is missing: %s\n' "$dependency" >&2
        exit 2
    fi
done
if command -v xcodegen >/dev/null 2>&1; then
    XCODEGEN="$(command -v xcodegen)"
elif [[ -x /usr/local/bin/xcodegen ]]; then
    XCODEGEN=/usr/local/bin/xcodegen
else
    printf 'error: XcodeGen is required in PATH or /usr/local/bin/xcodegen; no dependency was installed.\n' >&2
    exit 2
fi
if [[ ! -f "$EXAMPLE_DIR/project.yml" ]]; then
    printf 'error: missing project specification: %s\n' "$EXAMPLE_DIR/project.yml" >&2
    exit 2
fi

ARTIFACT_DIR="$(python3 - "$REPO_ROOT" "${ARTIFACT_DIR:-}" <<'PY_ARTIFACTS'
import datetime
import os
import pathlib
import sys

repo = pathlib.Path(sys.argv[1])
requested = sys.argv[2]
stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
path = pathlib.Path(requested).expanduser() if requested else repo / '.build' / 'ios18-validation' / stamp
path = path.absolute()
if path.exists() and (not path.is_dir() or any(path.iterdir())):
    sys.exit(f'error: ARTIFACT_DIR must be absent or empty; preserving existing contents: {path}')
path.mkdir(parents=True, exist_ok=True)
print(path)
PY_ARTIFACTS
)"
export ARTIFACT_DIR
exec > >(tee "$ARTIFACT_DIR/run.log") 2>&1
trap 'result=$?; printf "%s\n" "$result" > "$ARTIFACT_DIR/exit-code.txt"' EXIT

printf 'Repository: %s\nArtifacts: %s\n' "$REPO_ROOT" "$ARTIFACT_DIR"
xcodebuild -version | tee "$ARTIFACT_DIR/xcode-version.txt"
"$XCODEGEN" --version | tee "$ARTIFACT_DIR/xcodegen-version.txt"
xcrun simctl list runtimes --json > "$ARTIFACT_DIR/runtimes.json"
xcrun simctl list devices --json > "$ARTIFACT_DIR/devices.json"

python3 - "$ARTIFACT_DIR" "${SIMULATOR_UDID:-}" <<'PY_SELECT'
import json
import pathlib
import sys

directory = pathlib.Path(sys.argv[1])
requested = sys.argv[2].strip()
runtimes = json.loads((directory / 'runtimes.json').read_text())['runtimes']
devices = json.loads((directory / 'devices.json').read_text())['devices']
runtime_by_id = {runtime['identifier']: runtime for runtime in runtimes}

def is_ios18(runtime):
    return (runtime.get('isAvailable') is True
            and '.iOS-' in runtime.get('identifier', '')
            and runtime.get('version', '').split('.')[0] == '18')

def describe(device, runtime_id):
    runtime = runtime_by_id.get(runtime_id, {})
    return dict(udid=device['udid'], name=device.get('name', ''),
                state=device.get('state', ''), runtimeIdentifier=runtime_id,
                runtimeVersion=runtime.get('version', ''),
                deviceTypeIdentifier=device.get('deviceTypeIdentifier', ''))

all_devices = [(device, runtime_id) for runtime_id, group in devices.items() for device in group]
eligible = [(device, runtime_id) for device, runtime_id in all_devices
            if device.get('isAvailable') is True and is_ios18(runtime_by_id.get(runtime_id, {}))]
if requested:
    match = next(((device, runtime_id) for device, runtime_id in all_devices
                  if device['udid'].upper() == requested.upper()), None)
    if match is None:
        sys.exit(f'error: SIMULATOR_UDID does not identify an existing simulator: {requested}')
    if match not in eligible:
        detail = describe(*match)
        sys.exit('error: SIMULATOR_UDID must use an available iOS 18.x runtime and an available device; '
                 f"selected {detail['name']} ({detail['udid']}), runtime {detail['runtimeIdentifier']}. "
                 'No other OS was selected.')
    selected = match
else:
    candidates = [(device, runtime_id) for device, runtime_id in eligible
                  if device.get('name') == 'LiquidGlass-iOS18'
                  or 'SimDeviceType.iPhone-' in device.get('deviceTypeIdentifier', '')
                  or device.get('name', '').startswith('iPhone ')]
    if not candidates:
        sys.exit('error: no existing available iOS 18.x simulator named LiquidGlass-iOS18 or of iPhone type. '
                 'Install an iOS 18 runtime and create its device in Xcode, or provide a valid SIMULATOR_UDID. '
                 'No simulator was created and no other OS was selected.')
    def priority(item):
        device, runtime_id = item
        version = tuple(int(part) for part in runtime_by_id[runtime_id]['version'].split('.'))
        return (device.get('name') != 'LiquidGlass-iOS18',
                tuple(-part for part in version), device.get('state') != 'Booted',
                device.get('name', ''), device['udid'])
    selected = min(candidates, key=priority)

record = describe(*selected)
(directory / 'selected-simulator.json').write_text(json.dumps(record, indent=2) + '\n')
print(f"Selected: {record['name']} / iOS {record['runtimeVersion']} / {record['udid']}")
PY_SELECT

SIMULATOR_UDID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["udid"])' "$ARTIFACT_DIR/selected-simulator.json")"
printf '\nWaiting for the selected iOS 18 simulator to finish booting...\n'
xcrun simctl bootstatus "$SIMULATOR_UDID" -b 2>&1 | tee "$ARTIFACT_DIR/boot.log"

if [[ -d "$PROJECT" ]]; then
    cp -Rp "$PROJECT" "$ARTIFACT_DIR/project-before-generation.xcodeproj"
    printf 'Saved generated-project backup: %s\n' "$ARTIFACT_DIR/project-before-generation.xcodeproj"
fi
printf '\nGenerating the app-host test project...\n'
(
    cd "$EXAMPLE_DIR"
    "$XCODEGEN" generate --spec project.yml
) 2>&1 | tee "$ARTIFACT_DIR/xcodegen.log"

printf '\nRunning Metal, backdrop-capture and UI tests on iOS 18...\n'
set +e
xcodebuild test \
    -project "$PROJECT" \
    -scheme LiquidGlassDemo \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
    -destination-timeout 120 \
    -derivedDataPath "$ARTIFACT_DIR/DerivedData" \
    -resultBundlePath "$ARTIFACT_DIR/TestResults.xcresult" \
    -parallel-testing-enabled NO \
    -maximum-concurrent-test-simulator-destinations 1 \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    2>&1 | tee "$ARTIFACT_DIR/xcodebuild-test.log"
pipeline_status=("${PIPESTATUS[@]}")
set -e
test_status="${pipeline_status[0]}"
printf '%s\n' "$test_status" > "$ARTIFACT_DIR/xcodebuild-exit-code.txt"
printf '\nxcodebuild exit code: %s\nResult bundle: %s\nBuild log: %s\n' \
    "$test_status" "$ARTIFACT_DIR/TestResults.xcresult" "$ARTIFACT_DIR/xcodebuild-test.log"
if [[ "$test_status" -ne 0 ]]; then
    exit "$test_status"
fi
if [[ "${pipeline_status[1]}" -ne 0 ]]; then
    printf 'error: test log recording failed.\n' >&2
    exit "${pipeline_status[1]}"
fi
printf 'iOS 18 validation completed successfully.\n'
