/**
 * Generic repository interface.
 *
 * Defined in the domain layer, implemented in the infrastructure layer.
 * This inversion of control keeps the domain free of persistence concerns.
 */
export interface Repository<TEntity, TId = string> {
  /** Retrieve an entity by its unique identifier, or null if not found. */
  findById(id: TId): Promise<TEntity | null>;

  /** Persist an entity (insert or update). */
  save(entity: TEntity): Promise<void>;

  /** Remove an entity by its unique identifier. */
  delete(id: TId): Promise<void>;
}

/**
 * Extended repository with common query patterns.
 * Use this when you need listing capabilities beyond single-entity lookups.
 */
export interface ReadRepository<TEntity, TId = string> extends Repository<TEntity, TId> {
  /** Return all entities (use with caution on large datasets). */
  findAll(): Promise<TEntity[]>;

  /** Check existence without loading the full entity. */
  existsById(id: TId): Promise<boolean>;
}
