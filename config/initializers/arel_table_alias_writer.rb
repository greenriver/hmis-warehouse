# frozen_string_literal: true

# add back the ability to set table_aliase (removed in rails 6b56de4)
# FIXME: we shouldn't be using this private api
module ArelExtensions
  module TableAliasWriter
    def table_alias=(value)
      @table_alias = value
    end
  end
end

Arel::Table.include ArelExtensions::TableAliasWriter
