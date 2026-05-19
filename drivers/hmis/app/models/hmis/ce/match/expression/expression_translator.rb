# frozen_string_literal: true

require 'dentaku'

module Hmis::Ce::Match::Expression
  # Ce Match Rules have a free-text Dentaku `expression` field, like "current_age >= 18 AND veteran = TRUE".
  # Parsing uses `CalculatorFactory.build.ast` so the tokenizer sees the same
  # registration as evaluation (+INCLUDES+/+EXCLUDES+/…).
  #
  # For ease of editing and display, the frontend displays expressions as structured clauses with {field, comparator, value}.
  # This module translates between the free-text and structured forms.
  #
  # Currently, this module only supports translating a flat list of clauses joined by AND or OR.
  # If the expression is more complex, such as nested AND/OR or arithmetic, it will return +nil+.
  #
  # Possible later extensions (not implemented):
  # - Nested or mixed AND/OR
  # - Other allowlisted functions (+PROJECT_TYPE+, +EPOCH_SECONDS+, …)
  class ExpressionTranslator
    COMPARATORS = {
      Dentaku::AST::Equal => :EQ,
      Dentaku::AST::NotEqual => :NOT_EQ,
      Dentaku::AST::LessThan => :LT,
      Dentaku::AST::GreaterThan => :GT,
      Dentaku::AST::LessThanOrEqual => :LTE,
      Dentaku::AST::GreaterThanOrEqual => :GTE,
    }.freeze

    COMPARATOR_TO_TOKEN = {
      EQ: '=',
      NOT_EQ: '!=',
      LT: '<',
      GT: '>',
      LTE: '<=',
      GTE: '>=',
    }.freeze

    class << self
      # Parse +expression+ into a StructuredExpression, or +nil+ if it is blank, invalid, or not a flat AND/OR list of supported clauses.
      def to_structured(expression)
        return if expression.blank?

        ast = CalculatorFactory.build.ast(expression.strip)
        operator, leaves = boolean_leaves(ast)
        return unless leaves

        clauses = leaves.map { |node| clause_from_ast(node) }.compact
        return if clauses.size != leaves.size

        StructuredExpression.new(operator: operator, clauses: clauses)
      rescue Dentaku::Error
        nil
      end

      # Build a Dentaku expression string from a StructuredExpression (+AND+ / +OR+ and comparable clauses only).
      def from_structured(structured_expression)
        joiner = structured_expression.operator == :OR ? ' OR ' : ' AND '
        structured_expression.clauses.map { |c| clause_to_expression(c) }.join(joiner)
      end

      private

      # Returns +[:AND|:OR, leaf_ast_nodes]+, or +[:AND, [ast]]+ when the root is not +And+/+Or+.
      def boolean_leaves(ast)
        if ast.is_a?(Dentaku::AST::And)
          [:AND, flatten_combinator(ast, Dentaku::AST::And)]
        elsif ast.is_a?(Dentaku::AST::Or)
          [:OR, flatten_combinator(ast, Dentaku::AST::Or)]
        else
          [:AND, [ast]]
        end
      end

      # Recursively split +node+ into a flat array of children that are not wrapped in the same +klass+ (+And+ or +Or+).
      def flatten_combinator(node, klass)
        return [node] unless node.is_a?(klass)

        flatten_combinator(node.left, klass) + flatten_combinator(node.right, klass)
      end

      # Map one AST subtree to a Clause, or +nil+ when it is not a supported comparison or INCLUDES/EXCLUDES call.
      def clause_from_ast(node)
        if dentaku_function?(node, 'INCLUDES')
          function_includes_clause(node, :INCLUDES)
        elsif dentaku_function?(node, 'EXCLUDES')
          function_includes_clause(node, :EXCLUDES)
        elsif COMPARATORS.key?(node.class)
          comparison_clause(node)
        end
      end

      # True if +node+ is a Dentaku function with the given +name+ (e.g. +INCLUDES+).
      # We compare +#name+ strings because +add_function+ yields distinct Function AST classes per calculator instance.
      def dentaku_function?(node, name)
        node.is_a?(Dentaku::AST::Function) && node.name.to_s == name
      end

      # Build a Clause from +INCLUDES(field, value)+ / +EXCLUDES(field, value)+ (identifier first arg, literal second).
      def function_includes_clause(node, comparator)
        args = node.args
        return unless args&.size == 2
        return unless args.first.is_a?(Dentaku::AST::Identifier)
        return unless literal_ast?(args.last)

        field = args.first.identifier
        value = literal_value(args.last)
        StructuredExpression::Clause.new(field: field, comparator: comparator, value: value)
      end

      # Build a Clause from a comparator node (+=+, +!=+, +<+, etc.) with identifier on the left and a literal on the right.
      def comparison_clause(node)
        comparator_sym = COMPARATORS[node.class]
        return unless node.left.is_a?(Dentaku::AST::Identifier)
        return unless literal_ast?(node.right)

        value = literal_value(node.right)
        StructuredExpression::Clause.new(
          field: node.left.identifier,
          comparator: comparator_sym,
          value: value,
        )
      end

      # +true+ if +node+ is a Dentaku numeric, string, or boolean literal AST node.
      def literal_ast?(node)
        node.is_a?(Dentaku::AST::Numeric) ||
          node.is_a?(Dentaku::AST::String) ||
          node.is_a?(Dentaku::AST::Logical) ||
          node.is_a?(Dentaku::AST::Nil)
      end

      # Ruby value carried by a Dentaku literal node (+#value+ does not evaluate unbound identifiers here).
      def literal_value(node)
        node.value
      end

      # Serialize one Clause to a Dentaku fragment (function call or +field op value+).
      def clause_to_expression(clause)
        field_sql = quote_field(clause.field)
        comp = clause.comparator.to_sym

        if [:INCLUDES, :EXCLUDES].include?(comp)
          "#{comp}(#{field_sql}, #{quote_literal(clause.value)})"
        else
          "#{field_sql} #{COMPARATOR_TO_TOKEN.fetch(comp)} #{quote_literal(clause.value)}"
        end
      end

      SIMPLE_IDENTIFIER = /\A[a-zA-Z_][a-zA-Z0-9_]*\z/

      # Emit a bare identifier or backtick-quoted Dentaku identifier for dotted or special names.
      def quote_field(field)
        field = field.to_s
        if SIMPLE_IDENTIFIER.match?(field)
          field
        else
          "`#{field}`"
        end
      end

      # Emit +NULL+, +TRUE+/+FALSE+, numeric, or quoted string text for the right-hand side of a clause.
      def quote_literal(value)
        case value
        when NilClass
          'NULL'
        when TrueClass, FalseClass
          value ? 'TRUE' : 'FALSE'
        when Integer, Float
          value.to_s
        when String
          dentaku_string_literal(value)
        else
          value.to_s
        end
      end

      # Wrap +str+ in single or double quotes; Dentaku tokens do not support escapes inside quotes.
      def dentaku_string_literal(str)
        if str.exclude?("'")
          "'#{str}'"
        else
          %("#{str}")
        end
      end
    end
  end
end
