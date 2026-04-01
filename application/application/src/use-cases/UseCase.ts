/**
 * Generic Use Case interface.
 *
 * Each use case encapsulates a single user intention (command or query).
 * Input/output types are defined as DTOs at the use-case boundary.
 *
 * @typeParam TInput  - The request DTO accepted by this use case.
 * @typeParam TOutput - The response DTO returned by this use case.
 */
export interface UseCase<TInput, TOutput> {
  execute(input: TInput): Promise<TOutput>;
}

/**
 * Use case that produces no meaningful return value (side-effect only).
 */
export type CommandUseCase<TInput> = UseCase<TInput, void>;

/**
 * Use case that takes no input (e.g., "list all" queries).
 */
export type ParameterlessUseCase<TOutput> = UseCase<void, TOutput>;

/**
 * Result wrapper for use cases that can fail with domain-level errors
 * rather than throwing exceptions.
 */
export type UseCaseResult<TOutput, TError = string> =
  | { success: true; data: TOutput }
  | { success: false; error: TError };

/** Helper to create a successful result. */
export function ok<TOutput>(data: TOutput): UseCaseResult<TOutput, never> {
  return { success: true, data };
}

/** Helper to create a failure result. */
export function fail<TError = string>(error: TError): UseCaseResult<never, TError> {
  return { success: false, error };
}
