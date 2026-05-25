import type { NextFunction, Request, Response } from 'express';
import { randomUUID } from 'crypto';

export const requestLogger = (
  req: Request & { reqId?: string },
  res: Response,
  next: NextFunction
) => {
  req.reqId = randomUUID();
  const start = Date.now();
  res.on('finish', () => {
    console.log(
      JSON.stringify({
        reqId: req.reqId,
        method: req.method,
        path: req.path,
        status: res.statusCode,
        ms: Date.now() - start,
        uid: (req as any).user?.uid ?? null,
      })
    );
  });
  next();
};

export const log = {
  error: (msg: string, meta?: Record<string, unknown>) =>
    console.error(JSON.stringify({ level: 'error', msg, ...meta })),
  warn: (msg: string, meta?: Record<string, unknown>) =>
    console.warn(JSON.stringify({ level: 'warn', msg, ...meta })),
  info: (msg: string, meta?: Record<string, unknown>) =>
    console.log(JSON.stringify({ level: 'info', msg, ...meta })),
};
