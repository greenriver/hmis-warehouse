###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../../lib/rubocop/cop/queries/unsafe_bulk_update_sql'

RSpec.describe RuboCop::Cop::Queries::UnsafeBulkUpdateSql, :config do
  include RuboCop::RSpec::ExpectOffense

  let(:msg) { described_class::MSG }

  context 'with a raw SQL string literal' do
    it 'flags update_all' do
      expect_offense(<<~RUBY)
        clients.hmis.update_all("RaceNone = 99")
                     ^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'flags delete_all' do
      expect_offense(<<~RUBY)
        clients.delete_all("id = 1")
                ^^^^^^^^^^ #{msg}
      RUBY
    end

    it 'flags update_counters' do
      expect_offense(<<~RUBY)
        clients.update_counters("views = views + 1")
                ^^^^^^^^^^^^^^^ #{msg}
      RUBY
    end
  end

  context 'with an interpolated string' do
    it 'flags it' do
      expect_offense(<<~'RUBY')
        clients.update_all("RaceNone = #{value}")
                ^^^^^^^^^^ Avoid passing a raw SQL string to a bulk-update method; on joined relations Rails 8.1 aliases the target table so bare columns become ambiguous (PG::AmbiguousColumn). Use the Hash form (e.g. `update_all(col: value)`) or qualify every column and disable this cop with a comment. See docs/active-record-arel-and-queries.md.
      RUBY
    end
  end

  context 'with Arel.sql' do
    it 'flags it' do
      expect_offense(<<~RUBY)
        scope.update_all(Arel.sql("geom = ST_MakeValid(geom)"))
              ^^^^^^^^^^ #{msg}
      RUBY
    end
  end

  context 'with a string built by concatenation' do
    it 'flags it' do
      expect_offense(<<~RUBY)
        clients.update_all("col = " + value)
                ^^^^^^^^^^ #{msg}
      RUBY
    end
  end

  context 'with a .to_s argument' do
    it 'flags it' do
      expect_offense(<<~RUBY)
        clients.update_all(builder.to_s)
                ^^^^^^^^^^ #{msg}
      RUBY
    end
  end

  context 'when a string is assigned to a local variable then passed in (the metaprogrammed case)' do
    it 'flags it' do
      expect_offense(<<~RUBY)
        def fix!
          update_sql = "RaceNone = 99"
          clients.hmis.update_all(update_sql)
                       ^^^^^^^^^^ #{msg}
        end
      RUBY
    end

    it 'flags an interpolated string assigned to a local variable' do
      expect_offense(<<~'RUBY')
        def fix!
          update_sql = fields.map { |f| "#{f} = 0" }.join(", ")
          clients.update_all(update_sql)
                  ^^^^^^^^^^ Avoid passing a raw SQL string to a bulk-update method; on joined relations Rails 8.1 aliases the target table so bare columns become ambiguous (PG::AmbiguousColumn). Use the Hash form (e.g. `update_all(col: value)`) or qualify every column and disable this cop with a comment. See docs/active-record-arel-and-queries.md.
        end
      RUBY
    end
  end

  context 'with a Hash argument (the safe form)' do
    it 'does not flag a hash literal' do
      expect_no_offenses(<<~RUBY)
        clients.hmis.update_all(RaceNone: 99)
      RUBY
    end

    it 'does not flag a hash literal with a string value' do
      expect_no_offenses(<<~RUBY)
        clients.update_all(name: "Smith")
      RUBY
    end

    it 'does not flag a dynamic-key hash' do
      expect_no_offenses(<<~RUBY)
        scope.update_all(foreign_key => new_id)
      RUBY
    end

    it 'does not flag a hash returned by a method' do
      expect_no_offenses(<<~RUBY)
        klass.update_all(row.slice(columns))
      RUBY
    end

    it 'does not flag a local variable known to hold a hash' do
      expect_no_offenses(<<~RUBY)
        def fix!
          data = { name: "x" }
          clients.update_all(data)
        end
      RUBY
    end
  end

  context 'with unrelated methods' do
    it 'does not flag where with a string' do
      expect_no_offenses(<<~RUBY)
        clients.where("updated_at >= ?", old_date)
      RUBY
    end

    it 'does not flag update_all-like names on other receivers' do
      expect_no_offenses(<<~RUBY)
        logger.update_all
      RUBY
    end
  end
end
