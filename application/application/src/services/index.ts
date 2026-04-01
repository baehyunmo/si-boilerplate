import { DomainEvent } from '@si/domain';

/**
 * Dispatches domain events after an aggregate has been persisted.
 * Infrastructure layer provides the concrete implementation.
 */
export interface EventDispatcher {
  dispatch(events: DomainEvent[]): Promise<void>;
}

/**
 * Unit-of-work abstraction for transactional consistency.
 * Infrastructure layer provides the concrete implementation.
 */
export interface UnitOfWork {
  begin(): Promise<void>;
  commit(): Promise<void>;
  rollback(): Promise<void>;
}

/**
 * Base application service that coordinates use-case execution
 * with transaction management and event dispatching.
 */
export abstract class ApplicationService {
  constructor(
    protected readonly unitOfWork: UnitOfWork,
    protected readonly eventDispatcher: EventDispatcher,
  ) {}

  /** Run a block inside a transaction, dispatching events on success. */
  protected async withTransaction<T>(
    fn: () => Promise<{ result: T; events: DomainEvent[] }>,
  ): Promise<T> {
    await this.unitOfWork.begin();
    try {
      const { result, events } = await fn();
      await this.unitOfWork.commit();
      await this.eventDispatcher.dispatch(events);
      return result;
    } catch (error) {
      await this.unitOfWork.rollback();
      throw error;
    }
  }
}
