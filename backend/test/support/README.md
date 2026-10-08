# Test support

Black-box tests talk to the backend only over HTTP, never by importing
route handlers directly.

    import { startTestApp, type TestApp } from './support/test-app.js';

    let app: TestApp;
    beforeAll(async () => { app = await startTestApp(); });
    afterAll(async () => { await app.close(); });

    const res = await app.client().get('/api/v1/health');

Use `app.clock` (a `FakeClock`) to control token/session expiry
deterministically: `app.clock.advance(15 * 60 * 1000)`. Use `app.push` (a
`RecordingPushSender`) to assert what would have been pushed: `app.push.sent`,
`app.push.sentTo(deviceId)`, `app.push.markInvalid(token)`.

Call `app.restart(configOverrides?)` to simulate a server restart on the
same database (e.g. to test bootstrap idempotency); it returns a new
`TestApp` with a fresh clock/push sender. Pass `databaseUrl`/`config` into
`startTestApp()` directly only when you need to control them from the start.

The one allowed exception to black-box testing is asserting on database
constraints the API cannot reach yet — do that with a raw `pg.Pool` against
`app.databaseUrl`, as in `db-constraints.test.ts`.
