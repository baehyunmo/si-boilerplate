import type { BaseController, HttpRequest, HttpResponse } from '../controllers';

/**
 * Route definition for a framework-agnostic router.
 */
export interface RouteDefinition {
  method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  path: string;
  controller: BaseController<unknown, unknown>;
  middleware?: string[];
}

/**
 * Registry that collects route definitions.
 * Integrate this with your HTTP framework (Express, Fastify, Hono, etc.).
 */
export class RouteRegistry {
  private readonly routes: RouteDefinition[] = [];

  public register(route: RouteDefinition): void {
    this.routes.push(route);
  }

  public getRoutes(): ReadonlyArray<RouteDefinition> {
    return this.routes;
  }
}

/**
 * Adapter function: converts a BaseController into a plain request handler.
 * Use this to bridge into your HTTP framework of choice.
 */
export function toHandler(
  controller: BaseController<unknown, unknown>,
): (request: HttpRequest) => Promise<HttpResponse> {
  return (request) => controller.execute(request);
}
