/**
 * Abstract base class for Value Objects.
 *
 * Value Objects are compared by structural equality (all properties must match).
 * They are immutable — create a new instance rather than mutating.
 */
export abstract class ValueObject<TProps extends Record<string, unknown>> {
  protected readonly props: Readonly<TProps>;

  protected constructor(props: TProps) {
    this.props = Object.freeze({ ...props });
  }

  /** Structural equality: two Value Objects are equal when all their properties match. */
  public equals(other: ValueObject<TProps> | null | undefined): boolean {
    if (other === null || other === undefined) {
      return false;
    }
    if (this === other) {
      return true;
    }
    return this.shallowEquals(this.props, other.props);
  }

  private shallowEquals(a: Readonly<TProps>, b: Readonly<TProps>): boolean {
    const keysA = Object.keys(a) as Array<keyof TProps>;
    const keysB = Object.keys(b) as Array<keyof TProps>;

    if (keysA.length !== keysB.length) {
      return false;
    }

    return keysA.every((key) => a[key] === b[key]);
  }

  /** Return a plain object snapshot of the Value Object properties. */
  public toObject(): Readonly<TProps> {
    return this.props;
  }
}
