import { app } from './app';
import { env } from './config/env';
import { pingDb } from './config/db';

async function bootstrap() {
  try {
    await pingDb();
    // eslint-disable-next-line no-console
    console.log('[db] connected');
  } catch (err) {
    // eslint-disable-next-line no-console
    console.warn('[db] could not connect — server still starting', err);
  }
  app.listen(env.port, () => {
    // eslint-disable-next-line no-console
    console.log(`[konekta] api listening on http://localhost:${env.port}`);
  });
}

bootstrap();
