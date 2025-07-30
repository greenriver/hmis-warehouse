# frozen_string_literal: true

require 'dentaku'
require 'dentaku/visitor/infix'

# Transform an expression into arel based on the arel_fields in field_map. The translation may not be exact and allows untranslatable fields, replacing them with TRUE. The intention is to serve as a first-pass filter on a large record set to reduce the need for expensive application-side evaluations.

module Hmis::Ce::Match::Expression
  class SqlExpressionTranslator
    include Dentaku::Visitor::Infix

    # Class method for convenience, similar to how it's used in tests
    def self.call(expression, field_map)
      calculator = CalculatorFactory.build(current_date: field_map.current_date)
      begin
        ast = calculator.ast(expression)
      rescue Dentaku::Error => e
        err_with_context = "Error parsing expression '#{expression}': #{e.message}"
        raise e, err_with_context, e.backtrace
      end
      translator = new(field_map)
      translator.visit(ast)
      translator.to_arel
    end

    def initialize(field_map)
      @field_map = field_map
      @node_results = {}
      @joins = []
    end

    def visit_operation(node)
      visit(node.left)  if node.left
      visit(node.right) if node.right
      process(node)
    end

    def visit(node)
      return @node_results[node] if @node_results.key?(node)

      result = super
      @node_results[node] = result
      result
    end

    def visit_function(node)
      case node.name
      when 'DAYS_AGO'
        handle_days_ago_function(node)
      else
        ALWAYS_TRUE
      end
    end

    def joins
      @joins.uniq
    end

    def to_arel
      @node_results.values.last
    end

    private

    def handle_days_ago_function(node)
      # DAYS_AGO(date_field) should calculate the difference in days between current_date and date_field
      # We need to visit the argument to get the field/expression
      if node.args.length != 1
        return ALWAYS_TRUE # Invalid number of arguments
      end

      date_argument = node.args.first
      visit(date_argument)
      date_arel = @node_results[date_argument]

      # If the date argument couldn't be resolved to SQL, fall back to ALWAYS_TRUE
      return ALWAYS_TRUE if date_arel == ALWAYS_TRUE

      # Create SQL expression: current_date - date_field
      # This will return the number of days between current_date and the field
      Arel::Nodes::Subtraction.new(
        Arel::Nodes::Quoted.new(@field_map.current_date),
        date_arel,
      )
    end

    def process(node)
      case node
      when Dentaku::AST::Operation
        build_expression(node)
      when Dentaku::AST::Identifier
        handle_identifier(node)
      when Dentaku::AST::Numeric, Dentaku::AST::String, Dentaku::AST::Logical
        handle_literal(node)
      end
    end

    ALWAYS_TRUE = Arel::Nodes::Equality.new(1, 1).freeze

    def handle_identifier(node)
      join = @field_map.joins(node.identifier)
      @joins << join if join.present?
      @field_map.arel_field(node.identifier) || ALWAYS_TRUE
    end

    def handle_literal(node)
      Arel::Nodes::Quoted.new(node.value)
    end

    def build_expression(node)
      left = @node_results[node.left]
      right = @node_results[node.right]

      result = if comparison_operation?(node)
        build_comparison(node, left, right)
      elsif logical_operation?(node)
        build_logical(node, left, right)
      elsif arithmetic_operation?(node)
        build_arithmetic(node, left, right)
      else
        raise ArgumentError, "Unsupported expression: #{node.class}"
      end

      # Wrap mathematical expressions in parentheses
      Arel::Nodes::Grouping.new(result)
    end

    def find_parent(node)
      @node_results.keys.find { |n| n.is_a?(Dentaku::AST::Operation) && (n.left == node || n.right == node) }
    end

    def arithmetic_operation?(node)
      node.is_a?(Dentaku::AST::Arithmetic)
    end

    def comparison_operation?(node)
      node.is_a?(Dentaku::AST::Comparator)
    end

    def logical_operation?(node)
      node.is_a?(Dentaku::AST::Combinator)
    end

    def build_comparison(node, left, right)
      # If either operand could not be resolved into a SQL expression (is ALWAYS_TRUE),
      # then the entire comparison is also considered unresolvable in SQL.
      return ALWAYS_TRUE if left == ALWAYS_TRUE || right == ALWAYS_TRUE

      case node
      when Dentaku::AST::LessThan
        left.lt(right)
      when Dentaku::AST::GreaterThan
        left.gt(right)
      when Dentaku::AST::LessThanOrEqual
        left.lteq(right)
      when Dentaku::AST::GreaterThanOrEqual
        left.gteq(right)
      when Dentaku::AST::Equal
        left.eq(right)
      when Dentaku::AST::NotEqual
        left.not_eq(right)
      else
        raise ArgumentError, "Unsupported comparison operation: #{node.class}"
      end
    end

    def build_logical(node, left, right)
      case node
      when Dentaku::AST::And
        # For AND: if one side is unresolvable in SQL (ALWAYS_TRUE), return the other side
        return right if left == ALWAYS_TRUE
        return left if right == ALWAYS_TRUE

        left.and(right)
      when Dentaku::AST::Or
        # For OR: if either side is unresolvable in SQL (ALWAYS_TRUE), the result is unresolvable
        return ALWAYS_TRUE if left == ALWAYS_TRUE || right == ALWAYS_TRUE

        left.or(right)
      else
        raise ArgumentError, "Unsupported logical operation: #{node.class}"
      end
    end

    def build_arithmetic(node, left, right)
      case node
      when Dentaku::AST::Addition
        Arel::Nodes::Addition.new(left, right)
      when Dentaku::AST::Subtraction
        Arel::Nodes::Subtraction.new(left, right)
      when Dentaku::AST::Multiplication
        Arel::Nodes::Multiplication.new(left, right)
      when Dentaku::AST::Division
        Arel::Nodes::Division.new(left, right)
      when Dentaku::AST::Modulo
        Arel::Nodes::InfixOperation.new('%', left, right)
      when Dentaku::AST::Exponentiation
        Arel::Nodes::NamedFunction.new('POWER', [left, right])
      else
        raise ArgumentError, "Unsupported math operation: #{node.class}"
      end
    end
  end
end
