# frozen_string_literal: true

# FIXME: this should be removed once ActiveRecord updates how they merge relations containing SqlLiteral nodes
# for now, we'll pretend no SqlLiteral nodes are equal to eachother
# Allow skipping via env var so we can run a canary that ensures the issue is still present
unless ENV['SKIP_AREL_SQL_LITERAL_INITIALIZER'] == '1'
  module Arel::Nodes
    class SqlLiteral
      def equality? = false
    end
  end
end
