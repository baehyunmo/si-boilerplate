import type { HttpRequest, HttpResponse, ErrorBody } from '../controllers';

/**
 * Generic middleware function signature.
 * Receives a request and a next() callback, optionally short-circuits with a response.
 */
export type Middleware = (
  request: HttpRequest,
  next: () => Promise<HttpResponse>,
) => Promise<HttpResponse>;

/** Logs request method, path equivalent info, and response status. */
export const loggingMiddleware: Middleware = async (request, next) => {
  const start = Date.now();
  const response = await next();
  const duration = Date.now() - start;
  console.log(
    JSON.stringify({
      level: 'info',
      type: 'http',
      method: request.headers['x-http-method'] ?? 'UNKNOWN',
      status: response.statusCode,
      durationMs: duration,
      userId: request.user?.id,
    }),
  );
  return response;
};

/** Catches unhandled errors and returns a structured error response. */
export const errorHandlerMiddleware: Middleware = async (_request, next) => {
  try {
    return await next();
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unexpected error';
    console.error(JSON.stringify({ level: 'error', message, stack: error instanceof Error ? error.stack : undefined }));
    const body: ErrorBody = { error: 'Internal Server Error', message };
    return { statusCode: 500, body };
  }
};

/** Stub auth middleware -- replace with real token validation. */
export const authMiddleware: Middleware = async (request, next) => {
  const authHeader = request.headers['authorization'];
  if (!authHeader) {
    const body: ErrorBody = { error: 'Unauthorized', message: 'Missing authorization header' };
    return { statusCode: 401, body };
  }
  // TODO: Validate JWT / API key and populate request.user
  return next();
};
