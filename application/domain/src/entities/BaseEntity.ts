import { DomainEvent } from '../events/DomainEvent';

export abstract class BaseEntity<TId = string> {
  public readonly id: TId;
  public readonly createdAt: Date;
  public updatedAt: Date;

  private _domainEvents: DomainEvent[] = [];

  protected constructor(id: TId, createdAt?: Date, updatedAt?: Date) {
    this.id = id;
    this.createdAt = createdAt ?? new Date();
    this.updatedAt = updatedAt ?? new Date();
  }

  /** Mark entity as modified, bumping the updatedAt timestamp. */
  protected touch(): void {
    this.updatedAt = new Date();
  }

  /** Register a domain event to be dispatched after persistence. */
  protected addDomainEvent(event: DomainEvent): void {
    this._domainEvents.push(event);
  }

  /** Retrieve and clear all pending domain events. */
  public pullDomainEvents(): DomainEvent[] {
    const events = [...this._domainEvents];
    this._domainEvents = [];
    return events;
  }

  /** Entity equality is based on identity, not attributes. */
  public equals(other: BaseEntity<TId>): boolean {
    if (other === null || other === undefined) {
      return false;
    }
    if (this === other) {
      return true;
    }
    return this.id === other.id;
  }
}
