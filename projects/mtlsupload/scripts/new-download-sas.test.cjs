const { test } = require('node:test');
const assert = require('node:assert/strict');
const { mkdtempSync, writeFileSync, readFileSync, rmSync } = require('node:fs');
const { tmpdir } = require('node:os');
const { join, resolve } = require('node:path');
const { spawnSync } = require('node:child_process');

const script = join(__dirname, 'new-download-sas.sh');

test('notebook environment helpers resolve relocated project files from any working directory', () => {
  const project = resolve(__dirname, '..');
  for (const [helper, checks] of [
    ['signed-url', 'test "$SIGNED_TEMPLATE" = "$EXPECTED_PROJECT/afd/signed-url.bicep" && test -f "$SIGNED_TEMPLATE" && test -f "$SIGNED_ISSUER"'],
    ['ja4-upload', 'test "$JA4_TEMPLATE" = "$EXPECTED_PROJECT/afd/upload-ja4.bicep" && test -f "$JA4_TEMPLATE"'],
    ['edge-upload', 'test -f "$EDGE_REPO_ROOT/projects/mtlsupload/edge/upload-policy.js" && test "${#EDGE_VERSION}" -eq 13'],
  ]) {
    const result = spawnSync('bash', ['-euc', `source "$1"; ${checks}`, 'bash',
      join(project, 'notebooks', `${helper}.env.sh`)], {
      cwd: tmpdir(),
      encoding: 'utf8',
      env: { ...process.env, EXPECTED_PROJECT: project },
    });
    assert.equal(result.status, 0, `${helper}: ${result.stderr}`);
  }
});

function run(args, overrides = {}) {
  const dir = mkdtempSync(join(tmpdir(), 'download-sas-test-'));
  try {
    const calls = join(dir, 'args');
    writeFileSync(join(dir, 'az'), `#!/usr/bin/env bash
printf '%s\\n' "$@" > "$SAS_TEST_CALLS"
printf '%s' "$SAS_TEST_RESULT"
exit "$SAS_TEST_EXIT"
`, { mode: 0o700 });
    const result = spawnSync('bash', [script, ...args], {
      encoding: 'utf8',
      env: {
        ...process.env,
        PATH: `${dir}:${process.env.PATH}`,
        DOWNLOAD_STORAGE: 'demostorage',
        DOWNLOAD_CONTAINER: 'signed-downloads',
        AZURE_SUBSCRIPTION_ID: 'test-subscription',
        SAS_TEST_CALLS: calls,
        SAS_TEST_RESULT: 'sp=r&sr=b&spr=https&sig=test',
        SAS_TEST_EXIT: '0',
        ...overrides,
      },
    });
    let azArgs;
    if (result.status === 0) azArgs = readFileSync(calls, 'utf8').trim().split('\n');
    return { ...result, azArgs };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test('issues a read-only HTTPS blob SAS with a signed shared-cache lifetime', () => {
  const result = run(['folder/report.txt', '2', '600']);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout, 'sp=r&sr=b&spr=https&sig=test\n');
  const args = result.azArgs;
  for (const [flag, expected] of [
    ['--name', 'folder/report.txt'],
    ['--account-name', 'demostorage'],
    ['--container-name', 'signed-downloads'],
    ['--subscription', 'test-subscription'],
    ['--auth-mode', 'login'],
    ['--permissions', 'r'],
    ['--cache-control', 'max-age=0, s-maxage=600'],
  ]) {
    assert.equal(args[args.indexOf(flag) + 1], expected);
  }
  assert.ok(args.includes('--as-user'));
  assert.ok(args.includes('--https-only'));
  const expiry = Date.parse(args[args.indexOf('--expiry') + 1]);
  const remaining = expiry - Date.now();
  assert.ok(remaining > 50_000 && remaining <= 120_000, `remaining=${remaining}`);
});

test('rejects invalid lifetimes and missing blob arguments', () => {
  for (const args of [
    [], [''], ['file', '0'], ['file', '61'], ['file', '1;id'],
    ['file', '01'], ['file', '2', '0'], ['file', '2', '3601'],
    ['file', '2', '600', 'unexpected'],
  ]) {
    const result = run(args);
    assert.equal(result.status, 2, JSON.stringify(args));
    assert.equal(result.stdout, '');
    assert.notEqual(result.stderr, '');
  }
});

test('requires a storage account and surfaces CLI failures', () => {
  const missing = run(['file'], { DOWNLOAD_STORAGE: '' });
  assert.notEqual(missing.status, 0);
  assert.match(missing.stderr, /set DOWNLOAD_STORAGE/);
  const failure = run(['file'], { SAS_TEST_EXIT: '9', SAS_TEST_RESULT: '' });
  assert.equal(failure.status, 9);
  assert.equal(failure.stdout, '');
});

test('does not issue success-shaped output when CLI returns no SAS', () => {
  for (const value of ['', 'None', 'null']) {
    const result = run(['file'], { SAS_TEST_RESULT: value });
    assert.equal(result.status, 1);
    assert.equal(result.stdout, '');
    assert.match(result.stderr, /returned no SAS/);
  }
});

function runNotebookRequest(mode) {
  const dir = mkdtempSync(join(tmpdir(), 'download-request-test-'));
  try {
    const notebook = JSON.parse(readFileSync(join(__dirname, '../notebooks/signed-url.ipynb'), 'utf8'));
    const helpers = notebook.cells.find(cell => cell.cell_type === 'code'
      && cell.source.join('').startsWith('signed_request()')).source.join('');
    writeFileSync(join(dir, 'sleep'), '#!/usr/bin/env bash\nexit 0\n', { mode: 0o700 });
    writeFileSync(join(dir, 'curl'), `#!/usr/bin/env bash
while (( $# )); do
  case "$1" in
    --dump-header) headers="$2"; shift ;;
    --output) body="$2"; shift ;;
  esac
  shift
done
count=0
if [[ -f "$SIGNED_DIR/count" ]]; then count=$(< "$SIGNED_DIR/count"); fi
count=$((count + 1))
printf '%s' "$count" > "$SIGNED_DIR/count"
printf 'synthetic response' > "$body"
if [[ "$REQUEST_TEST_MODE" == origin && "$count" -gt 1 ]]; then
  printf 'HTTP/2 403\\r\\nx-ms-request-id: origin-request\\r\\n' > "$headers"
  printf 403
elif [[ "$REQUEST_TEST_MODE" == waf ]]; then
  printf 'HTTP/2 403\\r\\n' > "$headers"
  printf 403
else
  printf 'HTTP/2 404\\r\\nx-cache: CONFIG_NOCACHE\\r\\n' > "$headers"
  printf 404
fi
`, { mode: 0o700 });
    return spawnSync('bash', ['-c', `${helpers}\nsigned_request demo '403,404' GET https://example.invalid/file`], {
      encoding: 'utf8',
      env: {
        ...process.env,
        PATH: `${dir}:${process.env.PATH}`,
        SIGNED_DIR: dir,
        REQUEST_TEST_MODE: mode,
      },
    });
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test('notebook retries a generic Front Door 404 before accepting a Storage denial', () => {
  const result = runNotebookRequest('origin');
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stderr, /routing is still propagating/);
  assert.match(result.stdout, /demo: HTTP 403/);
});

test('notebook never accepts routing or WAF errors as proof of Storage authorization', () => {
  const generic = runNotebookRequest('generic');
  assert.equal(generic.status, 1);
  assert.match(generic.stderr, /no Storage response after bounded propagation retries/);
  const waf = runNotebookRequest('waf');
  assert.equal(waf.status, 1);
  assert.match(waf.stderr, /denial did not come from Storage/);
});
