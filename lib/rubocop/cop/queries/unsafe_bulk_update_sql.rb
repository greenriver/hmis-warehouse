###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module RuboCop
  module Cop
    module Queries
      # Flags raw SQL strings passed to bulk-update methods (`update_all`,
      # `delete_all`, `update_counters`).
      #
      # `update_all("col = ...")` embeds the string verbatim as the UPDATE's
      # SET clause. Since Rails 8.1, when the relation carries a join (directly
      # or through a scope such as `.hmis`), the PostgreSQL adapter aliases the
      # target table (`__active_record_update_alias`) and re-adds the real table
      # in a FROM, producing a self-join. Bare, unqualified column references in
      # the raw string then become ambiguous and Postgres raises
      # `PG::AmbiguousColumn`.
      #
      # The Hash form is always safe: ActiveRecord qualifies the SET columns and
      # binds the values, so nothing is ambiguous. Prefer it. If a raw SQL
      # expression is genuinely required, qualify every column explicitly and
      # disable this cop on the line with a comment explaining why.
      #
      # @example
      #   # bad
      #   clients.hmis.update_all("RaceNone = 99")
      #
      #   # bad - string built up then passed in (the metaprogrammed case)
      #   sql = "RaceNone = 99"
      #   clients.hmis.update_all(sql)
      #
      #   # good
      #   clients.hmis.update_all(RaceNone: 99)
      #
      # Limitation: a raw SQL string reaching a bulk method through a *method parameter*
      # (`def fix!(sql); rel.update_all(sql); end`) cannot be resolved statically and is a
      # known, accepted false-negative. Local/instance/class/global variables and
      # constants assigned in the enclosing scope are resolved.
      class UnsafeBulkUpdateSql < RuboCop::Cop::Base
        MSG = 'Avoid passing a raw SQL string to a bulk-update method; on joined relations Rails 8.1 aliases the ' \
              'target table so bare columns become ambiguous (PG::AmbiguousColumn). Use the Hash form ' \
              '(e.g. `update_all(col: value)`) or qualify every column and disable this cop with a comment. ' \
              'See docs/active-record-arel-and-queries.md.'

        RESTRICTED_METHODS = [:update_all, :delete_all, :update_counters].freeze

        # Method calls whose return value is (or is built from) a raw SQL string.
        STRING_PRODUCING_METHODS = [:to_s, :sql, :sanitize_sql, :sanitize_sql_for_assignment, :sanitize_sql_for_conditions, :format, :sprintf, :join, :+, :<<, :%].freeze

        # Variable/constant reference node type => its assignment node type. Used to trace
        # a reference back to what it was assigned in the enclosing scope.
        VAR_ASSIGNMENT_TYPES = { lvar: :lvasgn, ivar: :ivasgn, cvar: :cvasgn, gvar: :gvasgn, const: :casgn }.freeze

        def on_send(node)
          return unless RESTRICTED_METHODS.include?(node.method_name)
          return unless node.arguments.any? { |arg| sql_string?(arg) }

          add_offense(node.loc.selector)
        end

        private

        # Best-effort detection of an argument that is (or resolves to) a raw SQL
        # string. Hash arguments are always safe and never match here.
        def sql_string?(node, depth: 0)
          return false if node.nil? || depth > 3

          case node.type
          when :str, :dstr, :xstr
            true
          when :send
            string_producing_send?(node, depth: depth)
          when :lvar, :ivar, :cvar, :gvar, :const
            var_resolves_to_string?(node, depth: depth)
          else
            false
          end
        end

        def string_producing_send?(node, depth:)
          return true if STRING_PRODUCING_METHODS.include?(node.method_name)

          # A receiver that is itself a raw SQL string, e.g. ("a" + b).to_s
          sql_string?(node.receiver, depth: depth + 1)
        end

        # Trace a variable/constant reference back to its assignment(s) within the
        # enclosing method/block and check whether it holds a raw SQL string. This catches
        # the common `sql = "..."; rel.update_all(sql)` pattern (and the @ivar/CONST forms).
        def var_resolves_to_string?(node, depth:)
          asgn_type = VAR_ASSIGNMENT_TYPES[node.type]
          return false unless asgn_type

          name = variable_name(node)
          scope = enclosing_scope(node)
          return false unless scope

          scope.each_descendant(asgn_type).any? do |asgn|
            variable_name(asgn) == name && sql_string?(asgn.children.last, depth: depth + 1)
          end
        end

        # The bare name for a reference or an assignment. `const`/`casgn` carry a namespace
        # child first, so the name is the second element; simple vars carry it first.
        def variable_name(node)
          node.const_type? || node.casgn_type? ? node.children[1] : node.children.first
        end

        def enclosing_scope(node)
          node.each_ancestor(:def, :defs, :block, :begin).first
        end
      end
    end
  end
end
