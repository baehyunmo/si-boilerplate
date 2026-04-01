# Infrastructure Layer

Implements the technical capabilities defined by the domain and application layers.

## Rules

1. **Repository implementations** live here, fulfilling interfaces declared in the domain layer.
2. **External service adapters** (payment gateways, email providers, AI APIs) are encapsulated as adapters.
3. **Persistence** concerns (database connections, ORM configuration, migrations) belong here.
4. This layer depends on the **domain layer** (to implement its interfaces) but never on the interface layer.
5. All infrastructure code should be swappable without affecting domain or application logic.
