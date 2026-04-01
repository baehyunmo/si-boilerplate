/**
 * Framework-agnostic base controller.
 *
 * Provides a uniform request/response handling pattern. Concrete controllers
 * extend this class and implement the `handle` method.
 */

export interface HttpRequest<TBody = unknown, TParams = Record<string, string>, TQuery = Record<string, string>> {
  body: TBody;
  params: TParams;
  query: TQuery;
  headers: Record<string, string | string[] | undefined>;
  user?: { id: string; roles: string[] };
}

export interface HttpResponse<TData = unknown> {
  statusCode: number;
  body: TData;
  headers?: Record<string, string>;
}

export abstract class BaseController<TRequest = unknown, TResponse = unknown> {
  /** Subclasses implement the actual handling logic. */
  protected abstract handle(request: HttpRequest<TRequest>): Promise<HttpResponse<TResponse>>;

  /** Entry point that wraps handle() with error handling. */
  public async execute(request: HttpRequest<TRequest>): Promise<HttpResponse<TResponse | ErrorBody>> {
    try {
      return await this.handle(request);
    } catch (error) {
      return this.handleError(error);
    }
  }

  // ---- Response helpers ----

  protected ok<T>(data: T): HttpResponse<T> {
    return { statusCode: 200, body: data };
  }

  protected created<T>(data: T): HttpResponse<T> {
    return { statusCode: 201, body: data };
  }

  protected noContent(): HttpResponse<never> {
    return { statusCode: 204, body: undefined as never };
  }

  protected badRequest(message: string): HttpResponse<ErrorBody> {
    return { statusCode: 400, body: { error: 'Bad Request', message } };
  }

  protected unauthorized(message = 'Unauthorized'): HttpResponse<ErrorBody> {
    return { statusCode: 401, body: { error: 'Unauthorized', message } };
  }

  protected forbidden(message = 'Forbidden'): HttpResponse<ErrorBody> {
    return { statusCode: 403, body: { error: 'Forbidden', message } };
  }

  protected notFound(message = 'Not Found'): HttpResponse<ErrorBody> {
    return { statusCode: 404, body: { error: 'Not Found', message } };
  }

  private handleError(error: unknown): HttpResponse<ErrorBody> {
    const message = error instanceof Error ? error.message : 'Internal Server Error';
    return {
      statusCode: 500,
      body: { error: 'Internal Server Error', message },
    };
  }
}

export interface ErrorBody {
  error: string;
  message: string;
}
