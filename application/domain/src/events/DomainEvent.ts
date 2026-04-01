/**
 * Represents something meaningful that happened in the domain.
 *
 * Domain events are immutable records of facts. They are raised by entities
 * and dispatched after the aggregate is persisted, ensuring consistency.
 */
export interface DomainEvent<TPayload = unknown> {
  /** Globally unique identifier for this event instance. */
  readonly eventId: string;

  /** ISO-8601 timestamp of when the event occurred. */
  readonly occurredOn: string;

  /** Discriminator string used for routing and deserialization (e.g. "order.created"). */
  readonly eventType: string;

  /** Aggregate or entity ID that originated this event. */
  readonly aggregateId: string;

  /** Event-specific data. */
  readonly payload: TPayload;
}

/** Factory helper to create a DomainEvent with sensible defaults. */
export function createDomainEvent<TPayload>(
  params: Pick<DomainEvent<TPayload>, 'eventType' | 'aggregateId' | 'payload'> & {
    eventId?: string;
    occurredOn?: string;
  },
): DomainEvent<TPayload> {
  return {
    eventId: params.eventId ?? crypto.randomUUID(),
    occurredOn: params.occurredOn ?? new Date().toISOString(),
    eventType: params.eventType,
    aggregateId: params.aggregateId,
    payload: params.payload,
  };
}
