const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { test } = require('node:test');
const vm = require('node:vm');

const runtime = vm.createContext({});
vm.runInContext(readFileSync(`${__dirname}/upload-policy.js`, 'utf8'), runtime);

function upload(overrides = {}, headerOverrides = {}) {
    return {
        request: {
            uri: '/upload/edge/sample.json',
            method: 'PUT',
            query_string: '',
            body: '',
            ...overrides,
            headers: {
                'content-type': 'application/json',
                'content-length': '10',
                'x-ms-blob-type': 'BlockBlob',
                'x-upload-kind': 'telemetry',
                'x-device-id': 'device-042',
                ...headerOverrides,
            },
        },
        response: { response_code: 0, headers: {}, body: '' },
    };
}

test('only the edge prefix is processed', () => {
    for (const uri of ['/upload/sample.txt', '/upload/edge-other/sample.json']) {
        const event = upload({ uri, method: 'GET' });
        assert.equal(runtime.handler(event), event);
        assert.equal(event.response.response_code, 0);
        assert.equal(event.request.headers['x-ms-meta-policy_version'], undefined);
    }
});

test('both upload types accept the exact size limit and overwrite forged metadata', () => {
    for (const [kind, suffix, type, limit] of [
        ['telemetry', 'json', 'application/json', 1048576],
        ['diagnostics', 'zip', 'application/zip', 20971520],
    ]) {
        const event = upload({ uri: `/upload/edge/sample.${suffix}` }, {
            'x-upload-kind': kind,
            'content-type': type,
            'content-length': String(limit),
            'X-MS-Meta-Policy_Version': 'forged',
            'X-MS-Meta-Device_Id': 'other-device',
            'X-MS-Meta-Upload_Kind': 'forged',
            'X-Device-Id': 'device-007',
        });
        runtime.handler(event);
        assert.equal(event.response.response_code, 0);
        assert.equal(event.request.headers['x-ms-meta-policy_version'], 'v1');
        assert.equal(event.request.headers['x-ms-meta-device_id'], 'device-007');
        assert.equal(event.request.headers['x-ms-meta-upload_kind'], kind);
        assert.equal(event.request.headers['X-MS-Meta-Policy_Version'], undefined);
    }
});

test('invalid upload contracts are rejected with 403 and an explicit reason', () => {
    const cases = [
        [{ method: 'GET' }, {}, 'method-not-allowed'],
        [{ query_string: 'comp=metadata' }, {}, 'query-not-supported'],
        [{}, { 'x-ms-blob-type': 'AppendBlob' }, 'block-blob-required'],
        [{}, { 'x-device-id': undefined }, 'invalid-device-id'],
        [{}, { 'x-device-id': '../other' }, 'invalid-device-id'],
        [{}, { 'x-upload-kind': 'unknown' }, 'unknown-upload-kind'],
        [{ uri: '/upload/edge/../sample.json' }, {}, 'invalid-file-name'],
        [{ uri: '/upload/edge/sample.zip' }, {}, 'file-type-mismatch'],
        [{}, { 'content-type': 'text/plain' }, 'file-type-mismatch'],
        [{}, { 'content-length': undefined }, 'content-length-required'],
        [{}, { 'content-length': '-1' }, 'invalid-content-length'],
        [{}, { 'content-length': '1e3' }, 'invalid-content-length'],
        [{}, { 'content-length': '9007199254740992' }, 'invalid-content-length'],
        [{}, { 'content-length': '1048577' }, 'declared-size-exceeded'],
        [{ uri: '/upload/edge/sample.zip' }, {
            'x-upload-kind': 'diagnostics',
            'content-type': 'application/zip',
            'content-length': '20971521',
        }, 'declared-size-exceeded'],
    ];
    for (const [request, headers, reason] of cases) {
        const event = runtime.handler(upload(request, headers));
        assert.equal(event.response.response_code, 403, reason);
        assert.equal(event.response.headers['x-upload-error'], reason);
        assert.equal(event.response.headers['x-upload-policy'], 'v1');
        assert.equal(event.response.body, '');
        assert.equal(event.request.headers['x-ms-meta-policy_version'], undefined);
    }
});

test('a rejected method also advertises the allowed method', () => {
    const event = runtime.handler(upload({ method: 'GET' }));
    assert.equal(event.response.headers.allow, 'PUT');
});
