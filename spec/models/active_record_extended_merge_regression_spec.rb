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
# `SqlLiteral#equality? = false`. This file guards the workaround from two angles:
#
#   * The gated canary (run only under SKIP_AREL_SQL_LITERAL_INITIALIZER=1, which the
#     dedicated "ActiveRecord Smoke Test" CI job sets) DISABLES the initializer and asserts
#     the workaround is STILL required — i.e. Arel gives SqlLiteral no native `#equality?`.
#     It fails (signalling the initializer can finally be removed) only once Arel adds one.
#   * The behavioral block (initializer loaded — i.e. every normal CI run) asserts the
#     workaround actually WORKS: the patch is applied, mirrors Node's `false`, and a
#     relation carrying a SqlLiteral where-clause can be merged without raising.
RSpec.describe 'ActiveRecord SqlLiteral#equality? workaround' do
  it 'still needs the workaround: SqlLiteral has no native #equality?' do
    skip 'Set SKIP_AREL_SQL_LITERAL_INITIALIZER=1 to run this canary' unless ENV['SKIP_AREL_SQL_LITERAL_INITIALIZER'] == '1'

    expect(Arel::Nodes::SqlLiteral.new('x')).not_to respond_to(:equality?)
  end

  # Runs whenever the initializer is loaded (everything except the canary's dedicated job),
  # so it verifies the patch is present and does its job.
  context 'with the initializer loaded', unless: ENV['SKIP_AREL_SQL_LITERAL_INITIALIZER'] == '1' do
    before(:all) do
      ActiveRecord::Schema.define do
        create_table :sql_literal_merge_specs, force: true do |t|
          t.string :name
        end
      end

      class SqlLiteralMergeThing < ActiveRecord::Base
        self.table_name = 'sql_literal_merge_specs'
      end
    end

    after(:all) do
      Object.send(:remove_const, :SqlLiteralMergeThing)
      ActiveRecord::Schema.define do
        drop_table :sql_literal_merge_specs, force: true
      end
    end

    it 'defines #equality? on SqlLiteral' do
      expect(Arel::Nodes::SqlLiteral.new('x')).to respond_to(:equality?)
    end

    it 'mirrors Arel::Nodes::Node by returning false' do
      expect(Arel::Nodes::SqlLiteral.new('x').equality?).to be(false)
    end

    it 'merges a relation carrying a SqlLiteral where-clause without raising, returning the right rows' do
      keep = SqlLiteralMergeThing.create!(name: 'keep')
      SqlLiteralMergeThing.create!(name: 'drop')

      literal_scope = SqlLiteralMergeThing.where(Arel.sql("name = 'keep'"))
      merged = SqlLiteralMergeThing.all.merge(literal_scope)

      expect { merged.to_a }.not_to raise_error
      expect(merged.to_a).to eq([keep])
    end
  end
end
