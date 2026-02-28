import { HttpResponse, http as mswHttp } from 'msw';

import ENV from 'mssform/config/environment';

import { http } from './http';

const directUploadURL = new URL('/api/direct_uploads', ENV.apiURL).toString();

export const handlers = [
  http.get('/me', ({ response }) => {
    return response(200).json({
      uid: 'test-user',
    });
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
        url: `${ENV.apiURL}/rails/active_storage/disk/test`,
        headers: { 'Content-Type': 'application/octet-stream' },
      },
    });
  }),

  mswHttp.put(`${ENV.apiURL}/rails/active_storage/disk/*`, () => {
    return new HttpResponse(null, { status: 204 });
  }),
];
