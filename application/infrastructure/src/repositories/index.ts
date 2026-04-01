import type { Repository, BaseEntity } from '@si/domain';

/**
 * In-memory repository implementation for development and testing.
 * Replace with a real persistence-backed implementation for production.
 */
export class InMemoryRepository<TEntity extends BaseEntity<string>> implements Repository<TEntity, string> {
  protected readonly store = new Map<string, TEntity>();

  async findById(id: string): Promise<TEntity | null> {
    return this.store.get(id) ?? null;
  }

  async save(entity: TEntity): Promise<void> {
    this.store.set(entity.id, entity);
  }

  async delete(id: string): Promise<void> {
    this.store.delete(id);
  }

  /** Test helper: return current store size. */
  get size(): number {
    return this.store.size;
  }

  /** Test helper: clear all entries. */
  clear(): void {
    this.store.clear();
  }
}
