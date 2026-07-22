###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module RuboCop
  module Cop
    module Queries
      # Flags interpolating a Date/Time value directly into a SQL string.
      #
      # This app deliberately renders `Date#to_s` / `Time#to_s` in a human format
      # (e.g. "Jan 29, 2025") via config/initializers/legacy_rails_conversions.rb.
      # That format does NOT match ISO date literals, JSONB keys, or string
      # comparisons, so interpolating a bare date into SQL silently produces wrong
      # results (e.g. a JSONB `?` key lookup that never matches).
      #
      # Use an explicit, machine format instead: `.iso8601`, `.to_fs(:db)`, or
      # `.strftime(...)`. For values, prefer bind parameters (`where("x = ?", date)`)
      # or the Hash form. A *bare* `.to_fs`/`.to_formatted_s` (or a human format key such
      # as `:long`/`:default`) renders the human format and is NOT safe; only machine
      # format keys (`:db`, `:number`) are.
      #
      # @example
      #   # bad
      #   universe.members.where("pit_enrollments ? '#{pit_date}'")
      #   where("EntryDate <= '#{report_end_date}'")
      #
      #   # good
      #   universe.members.where("pit_enrollments ? '#{pit_date.iso8601}'")
      #   where('EntryDate <= ?', report_end_date)
      class DateInterpolationInSql < RuboCop::Cop::Base
        MSG = 'Avoid interpolating a Date/Time into a SQL string; `to_s` renders the app\'s human format ' \
              '(e.g. "Jan 29, 2025"), which will not match ISO date literals, JSONB keys, or string comparisons. ' \
              'Use `.iso8601`/`.to_fs(:db)`/`.strftime(...)`, or a bind parameter. ' \
              'See docs/active-record-arel-and-queries.md.'

        SQL_METHODS = [:where, :having, :execute, :exec_query, :exec_update, :exec_delete, :find_by_sql, :sanitize_sql, :sanitize_sql_for_conditions, :sanitize_sql_for_assignment].freeze

        # Methods whose result is a machine-formatted string or SQL fragment
        # (safe to interpolate): explicit date formatters, adapter quoting, and
        # Arel `to_sql` (which emits a column/expression reference, not a date).
        SAFE_FORMATTERS = [:iso8601, :strftime, :xmlschema, :rfc3339, :httpdate, :to_sql, :quote, :quoted_date, :to_json].freeze

        # `to_fs`/`to_formatted_s` are safe ONLY with a machine format argument. With no
        # argument (or a human key like :default/:long) they render the app's human format
        # (config/initializers/legacy_rails_conversions.rb + time.rb) and are unsafe.
        EXPLICIT_FORMAT_METHODS = [:to_fs, :to_formatted_s].freeze
        MACHINE_FORMAT_ARGS = [:db, :number].freeze

        # Interpolated expression source that looks like a date/time value.
        # Keyword must sit on a token boundary so "update"/"updates" (which
        # contain the substring "date") are not treated as dates.
        DATE_ISH = /(?:\A|[^a-z0-9])(?:date|datetime|timestamp|today)(?![a-z])|_at\b|_on\b/i

        def on_send(node)
          return unless sql_context?(node)

          node.arguments.each do |arg|
            each_sql_dstr(arg) { |dstr| flag_bad_interpolations(dstr) }
          end
        end

        private

        def sql_context?(node)
          return true if SQL_METHODS.include?(node.method_name)

          # Arel.sql("...")
          node.method?(:sql) && node.receiver&.const_type? && node.receiver.const_name == 'Arel'
        end

        # Yield every dstr (interpolated string) reachable from an argument: passed
        # directly, wrapped in Arel.sql(...), or assigned to a local variable first.
        def each_sql_dstr(arg, depth: 0, &block)
          return if arg.nil? || depth > 3

          case arg.type
          when :dstr
            yield arg
          when :send
            arg.arguments.each { |a| each_sql_dstr(a, depth: depth + 1, &block) }
          when :lvar
            resolve_lvar_dstr(arg, depth: depth, &block)
          end
        end

        def flag_bad_interpolations(dstr)
          dstr.each_child_node(:begin) do |interpolation|
            expr = interpolation.children.first
            next unless expr
            next unless date_ish?(expr)
            next if safely_formatted?(expr)
            next if safe_date_ish_lvar?(expr)

            add_offense(interpolation)
          end
        end

        def date_ish?(expr)
          expr.source.match?(DATE_ISH)
        end

        def safely_formatted?(expr)
          return false unless expr.send_type?
          return machine_formatted?(expr) if EXPLICIT_FORMAT_METHODS.include?(expr.method_name)

          SAFE_FORMATTERS.include?(expr.method_name)
        end

        # `to_fs(:db)` / `to_formatted_s(:number)` are safe; a bare call or a human
        # format key renders the app's human format and must still be flagged.
        def machine_formatted?(expr)
          arg = expr.first_argument
          arg&.sym_type? && MACHINE_FORMAT_ARGS.include?(arg.value)
        end

        # A date-ish *name* whose value is actually safe: a SQL string fragment
        # (`anniversary_date = <<~SQL ... SQL`) or an already-formatted/quoted
        # value (`deleted_at = conn.quote(Time.current)`) — not a raw Date.
        def safe_date_ish_lvar?(expr)
          return false unless expr.lvar_type?

          name = expr.children.first
          scope = enclosing_scope(expr)
          return false unless scope

          assigns = scope.each_descendant(:lvasgn).select { |asgn| asgn.children.first == name }
          # Only safe if the var is actually assigned in scope AND *every* reaching
          # assignment is itself safe. A single raw-date assignment anywhere on the path
          # must block the allow-list, otherwise "wrong assignment wins" and a genuinely
          # dangerous interpolation slips through.
          assigns.any? && assigns.all? do |asgn|
            rhs = asgn.children.last
            sql_string_node?(rhs) || safely_formatted?(rhs)
          end
        end

        def sql_string_node?(node)
          return false if node.nil?
          return true if node.str_type? || node.dstr_type?

          # Arel.sql(...)
          node.send_type? && node.method?(:sql) && node.receiver&.const_type? && node.receiver.const_name == 'Arel'
        end

        def resolve_lvar_dstr(node, depth:, &block)
          name = node.children.first
          scope = enclosing_scope(node)
          return unless scope

          scope.each_descendant(:lvasgn) do |asgn|
            next unless asgn.children.first == name

            each_sql_dstr(asgn.children.last, depth: depth + 1, &block)
          end
        end

        # The scope to search for a local variable's assignment. Prefer the
        # enclosing method, since a local assigned in the method body is visible
        # inside nested blocks (`with_temp(...) do ... #{var} ... end`); fall back
        # to the nearest block for block-scoped code. Deliberately excludes
        # `:begin` because a string interpolation is itself a `:begin` node.
        def enclosing_scope(node)
          node.each_ancestor(:def, :defs).first || node.each_ancestor(:block).first
        end
      end
    end
  end
end
