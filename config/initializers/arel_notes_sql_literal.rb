###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# ActiveRecord's relation merge calls `#equality?` on where-clause nodes. Arel defines it
# on Arel::Nodes::Node (returns false), but Arel::Nodes::SqlLiteral subclasses String (not
# Node) and so lacks it, raising NoMethodError when a SqlLiteral is merged.
# FIXME: remove this once Arel gives SqlLiteral its own #equality?.
# We mirror Node's behavior: pretend no SqlLiteral is equal to another.
# Allow skipping via env var so the canary spec can observe SqlLiteral's native behavior.
unless ENV['SKIP_AREL_SQL_LITERAL_INITIALIZER'] == '1'
  module Arel::Nodes
    class SqlLiteral
      def equality? = false
    end
  end
end
