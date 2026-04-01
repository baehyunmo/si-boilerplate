# Domain Layer

The innermost layer of the DDD architecture. This package contains **pure business logic** with zero external dependencies.

## Rules

1. **No framework dependencies** -- the domain must remain portable and testable in isolation.
2. **No infrastructure concerns** -- no database drivers, HTTP clients, or message brokers.
3. **Entities** encapsulate identity and lifecycle; equality is determined by `id`.
4. **Value Objects** are immutable and compared by structural equality.
5. **Domain Events** describe facts that have occurred within the domain.
6. **Repository interfaces** are defined here but **implemented in the infrastructure layer**.
7. All domain logic must be expressible through unit tests with no mocks for external systems.
