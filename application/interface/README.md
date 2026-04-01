# Interface Layer

The outermost layer that exposes the application to external consumers (HTTP, gRPC, CLI, etc.).

## Rules

1. Controllers translate external requests into application-layer DTOs and invoke use cases.
2. No business logic lives here -- controllers are thin adapters.
3. Middleware handles cross-cutting concerns: authentication, logging, error formatting.
4. Route definitions map HTTP verbs and paths to controller methods.
5. This layer depends on the **application layer** but never on infrastructure directly.
