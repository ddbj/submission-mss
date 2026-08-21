import { HttpResponse, http as mswHttp } from 'msw';

import ENV from 'mssform/config/environment';

import { http } from './http';

const directUploadURL = ENV.directUploadURL;

export const handlers = [
  // Nobody is signed in until a test says so: the session lives in a cookie,
  // and this is the only place the application can learn of one.
  http.get('/me', ({ response }) => {
    return response(401).empty();
  }),

  mswHttp.post(directUploadURL, () => {
    return HttpResponse.json({
      id: 1,
      key: 'test-key',
      filename: 'test.ann',
      content_type: 'application/octet-stream',
      metadata: {},
      byte_size: 100,
      checksum: 'abc123',
      created_at: new Date().toISOString(),
      service_name: 'local',
      signed_id: 'test-signed-id',

      direct_upload: {
        url: `${ENV.appURL}/rails/active_storage/disk/test`,
        headers: { 'Content-Type': 'application/octet-stream' },
      },
    });
  }),

  mswHttp.put(`${ENV.appURL}/rails/active_storage/disk/*`, () => {
    return new HttpResponse(null, { status: 204 });
  }),
];
