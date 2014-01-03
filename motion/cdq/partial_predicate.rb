
module CDQ

  # A partial predicate is an intermediate state while constructing a
  # query. It knows which attribute to use as the left operand, and
  # then offers a range of methods to specify which operation to use,
  # and what value to use as the right operand.  They are most commonly
  # created via the <tt>where</tt>, <tt>and</tt>, and <tt>or</tt>
  # methods on query, and sometimes via the main <tt>cdq</tt> method.

  class CDQPartialPredicate < CDQObject

    attr_reader :key, :scope, :operation

    def initialize(key, scope, operation = :and)
      @key = key
      @scope = scope
      @operation = operation
    end

    # Equality
    # @returns a new CDQQuery with the predicate appended
    def eq(value, options = 0);           make_scope(NSEqualToPredicateOperatorType, value, options); end

    # Inequality
    # @returns a new CDQQuery with the predicate appended
    def ne(value, options = 0);           make_scope(NSNotEqualToPredicateOperatorType, value, options); end

    # Less Than
    # @returns a new CDQQuery with the predicate appended
    def lt(value, options = 0);           make_scope(NSLessThanPredicateOperatorType, value, options); end

    # Less Than or Equal To
    # @returns a new CDQQuery with the predicate appended
    def le(value, options = 0);           make_scope(NSLessThanOrEqualToPredicateOperatorType, value, options); end

    # Greater Than
    # @returns a new CDQQuery with the predicate appended
    def gt(value, options = 0);           make_scope(NSGreaterThanPredicateOperatorType, value, options); end

    # Greater Than or Equal To
    # @returns a new CDQQuery with the predicate appended
    def ge(value, options = 0);           make_scope(NSGreaterThanOrEqualToPredicateOperatorType, value, options); end

    # Contains Substring
    # @returns a new CDQQuery with the predicate appended
    def contains(substr, options = 0);    make_scope(NSContainsPredicateOperatorType, substr, options); end

    # Matches Regexp
    # @returns a new CDQQuery with the predicate appended
    def matches(regexp, options = 0);     make_scope(NSMatchesPredicateOperatorType, regexp, options); end

    # List membership
    # @returns a new CDQQuery with the predicate appended
    def in(list, options = 0);            make_scope(NSInPredicateOperatorType, list, options); end

    # Begins With String
    # @returns a new CDQQuery with the predicate appended
    def begins_with(substr, options = 0); make_scope(NSBeginsWithPredicateOperatorType, substr, options); end

    # Ends With String
    # @returns a new CDQQuery with the predicate appended
    def ends_with(substr, options = 0);   make_scope(NSEndsWithPredicateOperatorType, substr, options); end

    # Between Min and Max Values
    # @returns a new CDQQuery with the predicate appended
    def between(min, max);                make_scope(NSBetweenPredicateOperatorType, [min, max]); end


    alias_method :equal, :eq
    alias_method :not_equal, :ne
    alias_method :less_than, :lt
    alias_method :less_than_or_equal, :le
    alias_method :greater_than, :gt
    alias_method :greater_than_or_equal, :ge
    alias_method :include, :contains


    private

    def make_pred(key, type, value, options = 0)
      NSComparisonPredicate.predicateWithLeftExpression(
        NSExpression.expressionForKeyPath(key.to_s),
        rightExpression:NSExpression.expressionForConstantValue(value),
        modifier:NSDirectPredicateModifier,
        type:type,
        options:options)
    end

    def make_scope(type, value, options = 0)
      scope.send(operation, make_pred(key, type, value, options), key)
    end

  end
end

