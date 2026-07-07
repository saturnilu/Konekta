// ============================================================
// Auth Module — barrel export
// App.ts hanya import dari sini, tidak langsung dari file internal.
// ============================================================

import authRouter from './auth.routes';
import googleAuthRouter from './googleAuth.routes';

export { authRouter, googleAuthRouter };
