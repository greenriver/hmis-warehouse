###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# ActiveRecord's relation merge calls `#equality?` on where-clause nodes. Arel defines
# `#equality?` on `Arel::Nodes::Node` (returns false), but `Arel::Nodes::SqlLiteral`
# subclasses String — not Node — so it does NOT inherit that method, and a SqlLiteral in
# a merged where clause raises `NoMethodError (equality?)`.
#
# config/initializers/arel_notes_sql_literal.rb works around this by defining
# `SqlLiteral#equality? = false`. This canary disables that initializer (via
# SKIP_AREL_SQL_LITERAL_INITIALIZER=1) and asserts the workaround is STILL required —
# i.e. that SqlLiteral has no native `#equality?`. It fails (signalling the initializer
# can finally be removed) only once Arel gives SqlLiteral its own `#equality?`.
#
# NOTE: this was previously reproduced through the HSR coc_filter report path, but Rails
# 8.1's merge no longer routes that report's SqlLiteral through `#equality?`. The root
# cause (SqlLiteral lacking the method) persists, so we assert it directly instead.
RSpec.describe 'ActiveRecord SqlLiteral#equality? workaround canary' do
  it 'still needs the workaround: SqlLiteral has no native #equality?' do
    skip 'Set SKIP_AREL_SQL_LITERAL_INITIALIZER=1 to run this canary' unless ENV['SKIP_AREL_SQL_LITERAL_INITIALIZER'] == '1'

    expect(Arel::Nodes::SqlLiteral.new('x')).not_to respond_to(:equality?)
  end
end
