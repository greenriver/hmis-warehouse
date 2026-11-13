###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'dentaku'

module Hmis::Ce::Match::Expression
  # Ce Match Rules have a free-text Dentaku `expression` field, like "current_age >= 18 AND veteran = 1".
  # Parsing uses `CalculatorFactory.build.ast` so the tokenizer sees the same
  # registration as evaluation (INCLUDES/EXCLUDES/…).
  #
  # For ease of editing and display, the frontend displays expressions as structured clauses with {field, comparator, value}.
  # This module translates between the free-text and structured forms. Enum-backed pick-list values are normalized at this
  # stage, so the frontend can use GraphQL enum keys while Dentaku expressions store literal values.
  # For example, the frontend uses "NoYesReasonsForMissingData" which has values of "YES", "NO", etc.,
  # but the Dentaku expression stores the literal values 0, 1, 99, etc.
  #
  # Currently, this module only supports translating a flat list of clauses joined by AND or OR.
  # If the expression is more complex, such as nested AND/OR or arithmetic, it will return nil.
  #
  # Possible later extensions (not implemented):
  # - Nested or mixed AND/OR
  # - Other allowlisted functions (PROJECT_TYPE, EPOCH_SECONDS, …)
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
      IS_NULL: '=',
      IS_NOT_NULL: '!=',
    }.freeze

    # A NULL RHS becomes IS_NULL/IS_NOT_NULL in the structured expression,
    # because this allows more precision in the API and frontend.
    # No other comparison node classes are included here, since "field < NULL" etc. aren't meaningful.
    NULL_COMPARATORS = {
      Dentaku::AST::Equal => :IS_NULL,
      Dentaku::AST::NotEqual => :IS_NOT_NULL,
    }.freeze

    FUNCTION_COMPARATORS = {
      'INCLUDES' => :INCLUDES,
      'EXCLUDES' => :EXCLUDES,
    }.freeze

    class << self
      def to_structured(expression, field_catalog: Hmis::Ce::Match::FieldCatalog.new)
        return if expression.blank?

        ast = CalculatorFactory.build.ast(expression.strip)
        operator, nodes = clause_nodes(ast)

        clauses = nodes.map { |node| clause_from_ast(node, field_catalog: field_catalog) }
        return if clauses.any?(&:nil?)

        StructuredExpression.new(operator: operator, clauses: clauses)
      rescue Dentaku::Error
        nil
      end

      def from_structured(structured_expression, field_catalog: Hmis::Ce::Match::FieldCatalog.new)
        joiner = structured_expression.operator == :OR ? ' OR ' : ' AND '
        structured_expression.clauses.map { |c| clause_to_expression(c, field_catalog: field_catalog) }.join(joiner)
      end

      private

      def clause_nodes(ast)
        # Preserve the top-level joiner (and/or), and flatten repeated uses of that same joiner from the AST.
        return [:AND, flatten_nodes(ast, Dentaku::AST::And)] if ast.is_a?(Dentaku::AST::And)
        return [:OR, flatten_nodes(ast, Dentaku::AST::Or)] if ast.is_a?(Dentaku::AST::Or)

        # A single clause has no boolean joiner; default to AND for the structured shape.
        [:AND, [ast]]
      end

      def flatten_nodes(node, klass)
        # Stop flattening as soon as another kind of node appears, since we don't support mixed/nested boolean groups.
        return [node] unless node.is_a?(klass)

        flatten_nodes(node.left, klass) + flatten_nodes(node.right, klass)
      end

      def clause_from_ast(node, field_catalog:)
        # Returns nil for any node that does not map to a supported clause,
        # which will cause the whole translation to return nil.
        function_comparator = FUNCTION_COMPARATORS[function_name(node)]
        if function_comparator
          function_clause(node, function_comparator, field_catalog: field_catalog)
        elsif COMPARATORS.key?(node.class)
          comparison_clause(node, field_catalog: field_catalog)
        end
      end

      def function_name(node)
        # Custom functions get calculator-specific AST classes, so compare by name.
        node.name.to_s if node.is_a?(Dentaku::AST::Function)
      end

      def function_clause(node, comparator, field_catalog:)
        args = node.args
        return unless args&.size == 2 # INCLUDES and EXCLUDES each take two arguments
        return unless args.first.is_a?(Dentaku::AST::Identifier)
        return unless literal_ast?(args.last)

        field = args.first.identifier
        field_metadata = field_catalog.field_for(field)
        return unless field_metadata

        value = structured_value_for_expression_value(args.last.value, field_metadata)

        StructuredExpression::Clause.new(
          field: field,
          comparator: comparator,
          value: value,
          # Return field_source and form_definition_identifier as helpers to the frontend
          # for filling in the related dropdowns when editing existing clauses.
          field_source: field_metadata.source,
          form_definition_identifier: field_metadata.form_definition_identifier,
        )
      end

      def comparison_clause(node, field_catalog:)
        # only supports parsing comparison where identifier is on the left
        # (can parse "current_age > 18" but not "18 < current_age")
        return unless node.left.is_a?(Dentaku::AST::Identifier)
        return unless literal_ast?(node.right)

        field = node.left.identifier
        field_metadata = field_catalog.field_for(field)
        return unless field_metadata

        comparator, value = if node.right.is_a?(Dentaku::AST::Nil) && NULL_COMPARATORS.key?(node.class)
          # If RHS is nil, use the NULL_COMPARATORS mapping to get the structured comparator. Value is always nil.
          [NULL_COMPARATORS.fetch(node.class), nil]
        else
          # Otherwise, use the COMPARATORS mapping to get the structured comparator and value.
          [COMPARATORS.fetch(node.class), structured_value_for_expression_value(node.right.value, field_metadata)]
        end

        StructuredExpression::Clause.new(
          field: field,
          comparator: comparator,
          value: value,
          # Return field_source and form_definition_identifier as helpers to the frontend
          # for filling in the related dropdowns when editing existing clauses.
          field_source: field_metadata.source,
          form_definition_identifier: field_metadata.form_definition_identifier,
        )
      end

      def literal_ast?(node)
        [
          Dentaku::AST::Numeric,
          Dentaku::AST::String,
          Dentaku::AST::Logical,
          Dentaku::AST::Nil,
        ].any? { |klass| node.is_a?(klass) }
      end

      def clause_to_expression(clause, field_catalog:)
        field = quote_field(clause.field)
        comparator = clause.comparator.to_sym
        expression_value = format_value_for_expression(clause.value, field: field_catalog&.field_for(clause.field), comparator: comparator)

        if FUNCTION_COMPARATORS.value?(comparator)
          # If this is a function like INCLUDES, format as "INCLUDES(foo, 1)"
          "#{comparator}(#{field}, #{expression_value})"
        else
          # Otherwise, format as a comparison like "foo = 1"
          "#{field} #{COMPARATOR_TO_TOKEN.fetch(comparator)} #{expression_value}"
        end
      end

      def quote_field(field)
        field = field.to_s
        if /\A[a-zA-Z_][a-zA-Z0-9_]*\z/.match?(field)
          # Simple identifiers are passed through as-is.
          field
        else
          # Dotted CDE/custom-assessment keys must be quoted to parse as one Dentaku identifier.
          "`#{field}`"
        end
      end

      def format_value_for_expression(value, field:, comparator:)
        return 'NULL' if NULL_COMPARATORS.values.include?(comparator)

        value = expression_value_for_structured_value(value, field)

        case value
        when NilClass
          # Dentaku uses SQL-like NULL for nil literals.
          'NULL'
        when TrueClass, FalseClass
          # Keep booleans uppercase to match existing CE match rule expressions.
          value ? 'TRUE' : 'FALSE'
        when Integer, Float
          value.to_s
        when String
          # Strings need Dentaku quote syntax; bare strings would be parsed as identifiers.
          dentaku_string_literal(value)
        else
          value.to_s
        end
      end

      def expression_value_for_structured_value(value, field)
        enum_type = pick_list_enum_type_for_field(field)
        return value unless enum_type

        # Structured clauses store GraphQL enum keys, e.g. "YES"; Dentaku expressions store raw enum values, e.g. 1.
        return value.map { |v| value_for_enum_key(v, enum_type) } if value.is_a?(Array)

        value_for_enum_key(value, enum_type)
      end

      def structured_value_for_expression_value(value, field)
        enum_type = pick_list_enum_type_for_field(field)
        return value unless enum_type

        # Dentaku expressions store raw enum values, e.g. 1; structured clauses store GraphQL enum keys, e.g. "YES".
        return value.map { |v| enum_key_for_value(v, enum_type) } if value.is_a?(Array)

        enum_key_for_value(value, enum_type)
      end

      def value_for_enum_key(value, enum_type)
        key = value.to_s
        enum_type.values.key?(key) ? enum_type.value_for(key) : value
      end

      def enum_key_for_value(value, enum_type)
        enum_type.enum_member_for_value(value)&.first || value
      end

      def pick_list_enum_type_for_field(field)
        return if field&.pick_list_reference.blank?

        HmisSchema.get_type(field.pick_list_reference)
      end

      def dentaku_string_literal(str)
        # Dentaku string tokens don't support escaped quotes. Choose the quote type that fits
        if str.exclude?("'")
          "'#{str}'"
        else
          %("#{str}")
        end
      end
    end
  end
end
