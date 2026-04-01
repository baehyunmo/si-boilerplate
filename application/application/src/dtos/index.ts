/**
 * DTO (Data Transfer Object) types.
 *
 * DTOs carry data across layer boundaries. They are plain serializable
 * objects with no behavior. Define your request/response DTOs here.
 */

/** Pagination parameters accepted by list endpoints. */
export interface PaginationInput {
  readonly page: number;
  readonly limit: number;
}

/** Standard paginated response wrapper. */
export interface PaginatedOutput<T> {
  readonly items: T[];
  readonly total: number;
  readonly page: number;
  readonly limit: number;
  readonly totalPages: number;
}

/** Build a PaginatedOutput from a dataset slice. */
export function paginate<T>(
  items: T[],
  total: number,
  pagination: PaginationInput,
): PaginatedOutput<T> {
  return {
    items,
    total,
    page: pagination.page,
    limit: pagination.limit,
    totalPages: Math.ceil(total / pagination.limit),
  };
}
