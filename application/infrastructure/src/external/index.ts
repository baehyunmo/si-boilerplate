/**
 * External service adapter interfaces and base implementations.
 *
 * Each external system (AI provider, payment gateway, notification service)
 * should have its own adapter that implements a port defined in the domain
 * or application layer.
 */

export interface HttpClientConfig {
  baseUrl: string;
  timeout: number;
  headers?: Record<string, string>;
}

/**
 * Minimal HTTP client abstraction for external service adapters.
 * Wrap your preferred HTTP library (axios, undici, node-fetch) behind this.
 */
export abstract class ExternalServiceAdapter {
  protected readonly config: HttpClientConfig;

  constructor(config: HttpClientConfig) {
    this.config = config;
  }

  /** Override to add auth headers, retries, circuit-breaking, etc. */
  protected buildHeaders(): Record<string, string> {
    return {
      'Content-Type': 'application/json',
      ...this.config.headers,
    };
  }

  /** Health check for the external service. */
  abstract healthCheck(): Promise<boolean>;
}
