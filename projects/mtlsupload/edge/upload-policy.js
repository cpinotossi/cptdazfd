function handler(event) {
    const request = event.request;
    if (!request.uri.startsWith('/upload/edge/')) {
        return event;
    }

    const headers = {};
    for (const name of Object.keys(request.headers)) {
        headers[name.toLowerCase()] = request.headers[name];
    }
    request.headers = headers;

    // Front Door ends a request only with 401 or 403 (other codes are ignored and the request continues).
    // The specific reason travels in x-upload-error; the response has no body.
    function reject(reason) {
        event.response.response_code = 403;
        event.response.headers['x-upload-policy'] = 'v1';
        event.response.headers['x-upload-error'] = reason;
        return event;
    }

    if (request.method !== 'PUT') {
        event.response.headers.allow = 'PUT';
        return reject('method-not-allowed');
    }
    // This path supports single Put Blob uploads, not staged blocks or metadata operations.
    if (request.query_string) {
        return reject('query-not-supported');
    }
    if (headers['x-ms-blob-type'] !== 'BlockBlob') {
        return reject('block-blob-required');
    }

    const kind = headers['x-upload-kind'];
    const device = headers['x-device-id'];
    if (!device || !/^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$/.test(device)) {
        return reject('invalid-device-id');
    }

    let extension;
    let contentType;
    let maxBytes;
    if (kind === 'diagnostics') {
        extension = '.zip';
        contentType = 'application/zip';
        maxBytes = 20 * 1024 * 1024;
    } else if (kind === 'telemetry') {
        extension = '.json';
        contentType = 'application/json';
        maxBytes = 1024 * 1024;
    } else {
        return reject('unknown-upload-kind');
    }

    const fileName = request.uri.slice('/upload/edge/'.length);
    if (!/^[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}$/.test(fileName)) {
        return reject('invalid-file-name');
    }
    if (!fileName.endsWith(extension) || headers['content-type'] !== contentType) {
        return reject('file-type-mismatch');
    }
    const length = headers['content-length'];
    if (length === undefined) {
        return reject('content-length-required');
    }
    if (!/^\d+$/.test(length) || !Number.isSafeInteger(Number(length))) {
        return reject('invalid-content-length');
    }
    if (Number(length) > maxBytes) {
        return reject('declared-size-exceeded');
    }

    headers['x-ms-meta-upload_kind'] = kind;
    headers['x-ms-meta-device_id'] = device;
    headers['x-ms-meta-policy_version'] = 'v1';
    return event;
}
