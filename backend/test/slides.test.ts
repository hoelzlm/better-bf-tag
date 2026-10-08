import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs, signTestAccessToken } from './support/create-person.js';
import { connectWs } from './support/ws-client.js';

interface SlideImageJson {
  content_type: string;
  size_bytes: number;
  version: string;
}

interface SlideJson {
  id: string;
  title: string;
  body: string;
  duration_seconds: number;
  sort_order: number;
  active: boolean;
  image: SlideImageJson | null;
  created_at: string;
  updated_at: string;
}

// Tiny hand-made byte buffers, just enough to pass magic-byte sniffing.
const PNG_BYTES = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00]);
const JPEG_BYTES = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46]);
const WEBP_BYTES = Buffer.concat([
  Buffer.from('RIFF', 'ascii'),
  Buffer.from([0x00, 0x00, 0x00, 0x00]),
  Buffer.from('WEBP', 'ascii'),
  Buffer.from([0x00, 0x00, 0x00, 0x00]),
]);
const GIF_BYTES = Buffer.from('GIF89a', 'ascii');

async function uploadImage(
  app: TestApp,
  slideId: string,
  token: string,
  contentType: string,
  bytes: Buffer
): Promise<{ status: number; body: unknown; headers: Headers }> {
  const res = await fetch(`${app.baseUrl}/api/v1/slides/${slideId}/image`, {
    method: 'POST',
    headers: { authorization: `Bearer ${token}`, 'content-type': contentType },
    body: bytes,
  });
  const text = await res.text();
  let body: unknown = null;
  if (text) {
    try {
      body = JSON.parse(text);
    } catch {
      body = text;
    }
  }
  return { status: res.status, body, headers: res.headers };
}

async function getImage(
  app: TestApp,
  slideId: string,
  token: string,
  ifNoneMatch?: string
): Promise<{ status: number; headers: Headers; bytes: Buffer }> {
  const headers: Record<string, string> = { authorization: `Bearer ${token}` };
  if (ifNoneMatch) headers['if-none-match'] = ifNoneMatch;
  const res = await fetch(`${app.baseUrl}/api/v1/slides/${slideId}/image`, { headers });
  const arrayBuffer = await res.arrayBuffer();
  return { status: res.status, headers: res.headers, bytes: Buffer.from(arrayBuffer) };
}

describe('slides', () => {
  let app: TestApp;
  let adminToken: string;
  let dispatchToken: string;
  let crewToken: string;
  let monitorToken: string;

  beforeAll(async () => {
    app = await startTestApp({ config: { SLIDE_IMAGE_MAX_BYTES: 1024 } });

    adminToken = await loginAs(app, 'admin', 'admin-password');

    await createPerson(app, {
      displayName: 'Leitstelle',
      personType: 'supervisor',
      permission: 'dispatch',
      username: 'dispatch1',
      password: 'dispatch-password',
    });
    dispatchToken = await loginAs(app, 'dispatch1', 'dispatch-password');

    const crewPerson = await createPerson(app, {
      displayName: 'Mannschaft',
      personType: 'youth',
      permission: 'crew',
      username: 'crew1',
      password: 'crew-password',
    });
    crewToken = await signTestAccessToken(app, crewPerson.id, 'crew');

    const monitorRes = await app
      .client()
      .post('/api/v1/monitors', { name: 'Standby' }, { token: adminToken });
    const monitorId = (monitorRes.body as { id: string }).id;
    const codeRes = await app
      .client()
      .post(`/api/v1/monitors/${monitorId}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as { code: string }).code;
    const pairRes = await app.client().post('/api/v1/auth/monitor/pair', { code });
    monitorToken = (pairRes.body as { access_token: string }).access_token;
  });

  afterAll(async () => {
    await app.close();
  });

  async function createSlide(overrides?: Record<string, unknown>) {
    const res = await app
      .client()
      .post('/api/v1/slides', { title: 'Folie', ...overrides }, { token: adminToken });
    expect(res.status).toBe(201);
    return res.body as SlideJson;
  }

  describe('permissions', () => {
    it('only admin may list/create/edit/delete/order slides', async () => {
      expect((await app.client().get('/api/v1/slides', { token: adminToken })).status).toBe(200);
      expect((await app.client().get('/api/v1/slides', { token: dispatchToken })).status).toBe(403);
      expect((await app.client().get('/api/v1/slides', { token: crewToken })).status).toBe(403);
      expect((await app.client().get('/api/v1/slides', { token: monitorToken })).status).toBe(403);
      expect((await app.client().get('/api/v1/slides')).status).toBe(401);

      const body = { title: 'X' };
      expect(
        (await app.client().post('/api/v1/slides', body, { token: dispatchToken })).status
      ).toBe(403);
      expect(
        (await app.client().post('/api/v1/slides', body, { token: monitorToken })).status
      ).toBe(403);
      expect((await app.client().post('/api/v1/slides', body)).status).toBe(401);

      const slide = await createSlide();

      expect(
        (
          await app
            .client()
            .patch(`/api/v1/slides/${slide.id}`, { title: 'Y' }, { token: dispatchToken })
        ).status
      ).toBe(403);
      expect((await app.client().patch(`/api/v1/slides/${slide.id}`, { title: 'Y' })).status).toBe(
        401
      );

      expect(
        (await app.client().delete(`/api/v1/slides/${slide.id}`, { token: dispatchToken })).status
      ).toBe(403);
      expect((await app.client().delete(`/api/v1/slides/${slide.id}`)).status).toBe(401);

      expect(
        (
          await app
            .client()
            .put('/api/v1/slides/order', { slide_ids: [] }, { token: dispatchToken })
        ).status
      ).toBe(403);
      expect((await app.client().put('/api/v1/slides/order', { slide_ids: [] })).status).toBe(401);
    });

    it('only admin may upload a slide image', async () => {
      const slide = await createSlide();
      expect((await uploadImage(app, slide.id, dispatchToken, 'image/png', PNG_BYTES)).status).toBe(
        403
      );
      expect((await uploadImage(app, slide.id, monitorToken, 'image/png', PNG_BYTES)).status).toBe(
        403
      );
      const noAuth = await fetch(`${app.baseUrl}/api/v1/slides/${slide.id}/image`, {
        method: 'POST',
        headers: { 'content-type': 'image/png' },
        body: PNG_BYTES,
      });
      expect(noAuth.status).toBe(401);
    });
  });

  describe('CRUD + ordering + validation', () => {
    it('creates a slide with defaults, appended at the end; lists in sort order', async () => {
      const first = await createSlide({ title: 'Erste' });
      expect(first).toMatchObject({
        title: 'Erste',
        body: '',
        duration_seconds: 10,
        active: true,
        image: null,
      });

      const second = await createSlide({ title: 'Zweite', duration_seconds: 20, active: false });
      expect(second.sort_order).toBe(first.sort_order + 1);

      const list = await app.client().get('/api/v1/slides', { token: adminToken });
      const ids = (list.body as SlideJson[]).map(s => s.id);
      expect(ids.indexOf(first.id)).toBeLessThan(ids.indexOf(second.id));
    });

    it('patches fields partially', async () => {
      const slide = await createSlide({ title: 'Original' });
      const patched = await app
        .client()
        .patch(
          `/api/v1/slides/${slide.id}`,
          { title: 'Neu', active: false },
          { token: adminToken }
        );
      expect(patched.status).toBe(200);
      expect(patched.body).toMatchObject({ title: 'Neu', active: false, body: '' });
    });

    it('patch on an unknown slide returns 404', async () => {
      const res = await app
        .client()
        .patch(
          '/api/v1/slides/00000000-0000-0000-0000-000000000000',
          { title: 'x' },
          { token: adminToken }
        );
      expect(res.status).toBe(404);
      expect(res.body).toMatchObject({ error: { code: 'not_found' } });
    });

    it('deletes a slide for real (gone from the list)', async () => {
      const slide = await createSlide();
      const res = await app.client().delete(`/api/v1/slides/${slide.id}`, { token: adminToken });
      expect(res.status).toBe(204);

      const list = await app.client().get('/api/v1/slides', { token: adminToken });
      expect((list.body as SlideJson[]).some(s => s.id === slide.id)).toBe(false);
    });

    it('rejects empty title, and duration outside 3..300', async () => {
      expect(
        (await app.client().post('/api/v1/slides', { title: '' }, { token: adminToken })).status
      ).toBe(400);
      expect(
        (
          await app
            .client()
            .post('/api/v1/slides', { title: 'x', duration_seconds: 2 }, { token: adminToken })
        ).status
      ).toBe(400);
      expect(
        (
          await app
            .client()
            .post('/api/v1/slides', { title: 'x', duration_seconds: 301 }, { token: adminToken })
        ).status
      ).toBe(400);
    });

    it('reorders slides; an invalid id set is rejected with 400', async () => {
      const freshApp = await startTestApp();
      try {
        const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
        const createOne = async (title: string) => {
          const res = await freshApp
            .client()
            .post('/api/v1/slides', { title }, { token: freshAdminToken });
          expect(res.status).toBe(201);
          return res.body as SlideJson;
        };
        const a = await createOne('A');
        const b = await createOne('B');
        const c = await createOne('C');

        const invalid = await freshApp
          .client()
          .put('/api/v1/slides/order', { slide_ids: [a.id, b.id] }, { token: freshAdminToken });
        expect(invalid.status).toBe(400);
        expect(invalid.body).toMatchObject({ error: { code: 'validation_error' } });

        const reordered = await freshApp
          .client()
          .put(
            '/api/v1/slides/order',
            { slide_ids: [c.id, a.id, b.id] },
            { token: freshAdminToken }
          );
        expect(reordered.status).toBe(200);
        expect((reordered.body as SlideJson[]).map(s => s.id)).toEqual([c.id, a.id, b.id]);
      } finally {
        await freshApp.close();
      }
    });
  });

  describe('image upload validation', () => {
    it('accepts a valid PNG, JPEG and WebP', async () => {
      for (const [contentType, bytes] of [
        ['image/png', PNG_BYTES],
        ['image/jpeg', JPEG_BYTES],
        ['image/webp', WEBP_BYTES],
      ] as const) {
        const slide = await createSlide();
        const res = await uploadImage(app, slide.id, adminToken, contentType, bytes);
        expect(res.status).toBe(200);
        const body = res.body as SlideJson;
        expect(body.image).toMatchObject({ content_type: contentType, size_bytes: bytes.length });
        expect(body.image!.version).toMatch(/^[0-9a-f]{16}$/);
      }
    });

    it('rejects a GIF with 415', async () => {
      const slide = await createSlide();
      const res = await uploadImage(app, slide.id, adminToken, 'image/gif', GIF_BYTES);
      expect(res.status).toBe(415);
      expect(res.body).toMatchObject({ error: { code: 'unsupported_image_type' } });
    });

    it('rejects a png content-type with jpeg bytes (magic byte mismatch) with 415', async () => {
      const slide = await createSlide();
      const res = await uploadImage(app, slide.id, adminToken, 'image/png', JPEG_BYTES);
      expect(res.status).toBe(415);
      expect(res.body).toMatchObject({ error: { code: 'unsupported_image_type' } });
    });

    it('rejects a body over the configured limit with 413', async () => {
      const slide = await createSlide();
      const tooBig = Buffer.concat([PNG_BYTES, Buffer.alloc(2000, 0)]);
      const res = await uploadImage(app, slide.id, adminToken, 'image/png', tooBig);
      expect(res.status).toBe(413);
      expect(res.body).toMatchObject({ error: { code: 'image_too_large' } });
    });

    it('rejects an empty body with 400', async () => {
      const slide = await createSlide();
      const res = await uploadImage(app, slide.id, adminToken, 'image/png', Buffer.alloc(0));
      expect(res.status).toBe(400);
      expect(res.body).toMatchObject({ error: { code: 'validation_error' } });
    });
  });

  describe('GET image', () => {
    it('admin and monitor get identical bytes + ETag; 304 with If-None-Match; 404 after DELETE image; image gone after slide DELETE', async () => {
      const slide = await createSlide();
      await uploadImage(app, slide.id, adminToken, 'image/png', PNG_BYTES);

      const asAdmin = await getImage(app, slide.id, adminToken);
      expect(asAdmin.status).toBe(200);
      expect(asAdmin.bytes.equals(PNG_BYTES)).toBe(true);
      expect(asAdmin.headers.get('content-type')).toBe('image/png');
      const etag = asAdmin.headers.get('etag');
      expect(etag).toBeTruthy();

      const asMonitor = await getImage(app, slide.id, monitorToken);
      expect(asMonitor.status).toBe(200);
      expect(asMonitor.bytes.equals(PNG_BYTES)).toBe(true);
      expect(asMonitor.headers.get('etag')).toBe(etag);

      const notModified = await getImage(app, slide.id, adminToken, etag!);
      expect(notModified.status).toBe(304);

      const deleteImageRes = await app
        .client()
        .delete(`/api/v1/slides/${slide.id}/image`, { token: adminToken });
      expect(deleteImageRes.status).toBe(204);

      const afterDeleteImage = await getImage(app, slide.id, adminToken);
      expect(afterDeleteImage.status).toBe(404);

      // idempotent
      const deleteAgain = await app
        .client()
        .delete(`/api/v1/slides/${slide.id}/image`, { token: adminToken });
      expect(deleteAgain.status).toBe(204);

      await uploadImage(app, slide.id, adminToken, 'image/jpeg', JPEG_BYTES);
      await app.client().delete(`/api/v1/slides/${slide.id}`, { token: adminToken });
      const afterSlideDelete = await getImage(app, slide.id, adminToken);
      expect(afterSlideDelete.status).toBe(404);
    });

    it('dispatch/crew tokens are forbidden on the image endpoint', async () => {
      const slide = await createSlide();
      await uploadImage(app, slide.id, adminToken, 'image/png', PNG_BYTES);
      expect((await getImage(app, slide.id, dispatchToken)).status).toBe(403);
      expect((await getImage(app, slide.id, crewToken)).status).toBe(403);
    });
  });

  describe('snapshot', () => {
    it('contains only active slides in order, with image metadata, for a monitor token', async () => {
      const freshApp = await startTestApp();
      try {
        const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
        const monitorRes = await freshApp
          .client()
          .post('/api/v1/monitors', { name: 'Standby snap' }, { token: freshAdminToken });
        const monitorId = (monitorRes.body as { id: string }).id;
        const codeRes = await freshApp
          .client()
          .post(`/api/v1/monitors/${monitorId}/pairing-code`, {}, { token: freshAdminToken });
        const pairRes = await freshApp
          .client()
          .post('/api/v1/auth/monitor/pair', { code: (codeRes.body as { code: string }).code });
        const freshMonitorToken = (pairRes.body as { access_token: string }).access_token;

        const active1 = await freshApp
          .client()
          .post('/api/v1/slides', { title: 'A' }, { token: freshAdminToken });
        const inactive = await freshApp
          .client()
          .post('/api/v1/slides', { title: 'B', active: false }, { token: freshAdminToken });
        const active2 = await freshApp
          .client()
          .post('/api/v1/slides', { title: 'C' }, { token: freshAdminToken });
        void inactive;

        const slideA = active1.body as SlideJson;
        const slideC = active2.body as SlideJson;
        await uploadImage(freshApp, slideA.id, freshAdminToken, 'image/png', PNG_BYTES);

        const snapshot = await freshApp
          .client()
          .get('/api/v1/snapshot', { token: freshMonitorToken });
        expect(snapshot.status).toBe(200);
        const slides = (snapshot.body as { slides: SlideJson[] }).slides;
        expect(slides.map(s => s.id)).toEqual([slideA.id, slideC.id]);
        expect(slides[0]!.image).toMatchObject({ content_type: 'image/png' });
        expect(slides[1]!.image).toBeNull();
      } finally {
        await freshApp.close();
      }
    });
  });

  describe('realtime', () => {
    it('a monitor WebSocket receives slides.changed with the full active list after create / deactivate / order', async () => {
      const freshApp = await startTestApp();
      try {
        const freshAdminToken = await loginAs(freshApp, 'admin', 'admin-password');
        const monitorRes = await freshApp
          .client()
          .post('/api/v1/monitors', { name: 'Standby rt' }, { token: freshAdminToken });
        const monitorId = (monitorRes.body as { id: string }).id;
        const codeRes = await freshApp
          .client()
          .post(`/api/v1/monitors/${monitorId}/pairing-code`, {}, { token: freshAdminToken });
        const pairRes = await freshApp
          .client()
          .post('/api/v1/auth/monitor/pair', { code: (codeRes.body as { code: string }).code });
        const freshMonitorToken = (pairRes.body as { access_token: string }).access_token;

        const ws = await connectWs(freshApp.baseUrl, freshMonitorToken);
        try {
          await ws.next(m => m.type === 'hello');

          const createRes = await freshApp
            .client()
            .post('/api/v1/slides', { title: 'A' }, { token: freshAdminToken });
          expect(createRes.status).toBe(201);
          const slideA = createRes.body as SlideJson;
          const createdEvent = await ws.next(m => m.type === 'slides.changed');
          expect((createdEvent.data as { slides: SlideJson[] }).slides.map(s => s.id)).toEqual([
            slideA.id,
          ]);

          const createRes2 = await freshApp
            .client()
            .post('/api/v1/slides', { title: 'B' }, { token: freshAdminToken });
          const slideB = createRes2.body as SlideJson;
          await ws.next(m => m.type === 'slides.changed');

          const deactivateRes = await freshApp
            .client()
            .patch(`/api/v1/slides/${slideA.id}`, { active: false }, { token: freshAdminToken });
          expect(deactivateRes.status).toBe(200);
          const deactivatedEvent = await ws.next(m => m.type === 'slides.changed');
          expect((deactivatedEvent.data as { slides: SlideJson[] }).slides.map(s => s.id)).toEqual([
            slideB.id,
          ]);

          const reactivate = await freshApp
            .client()
            .patch(`/api/v1/slides/${slideA.id}`, { active: true }, { token: freshAdminToken });
          expect(reactivate.status).toBe(200);
          await ws.next(m => m.type === 'slides.changed');

          const orderRes = await freshApp
            .client()
            .put(
              '/api/v1/slides/order',
              { slide_ids: [slideB.id, slideA.id] },
              { token: freshAdminToken }
            );
          expect(orderRes.status).toBe(200);
          const orderedEvent = await ws.next(m => m.type === 'slides.changed');
          expect((orderedEvent.data as { slides: SlideJson[] }).slides.map(s => s.id)).toEqual([
            slideB.id,
            slideA.id,
          ]);
        } finally {
          ws.close();
        }
      } finally {
        await freshApp.close();
      }
    });
  });
});
