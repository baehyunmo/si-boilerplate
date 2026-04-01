# Application Layer

Orchestrates domain logic to fulfill use cases. This layer sits between the interface (controllers) and the domain.

## Rules

1. **Use Cases** are the primary unit of work -- each represents a single user intention.
2. This layer depends on the **domain layer** but never on infrastructure or interface layers.
3. DTOs (Data Transfer Objects) are used to cross layer boundaries, keeping domain objects internal.
4. Application services coordinate entities and domain services but contain **no business logic**.
5. Transaction boundaries and event dispatching are managed here.
