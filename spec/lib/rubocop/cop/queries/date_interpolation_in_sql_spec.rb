###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../../lib/rubocop/cop/queries/date_interpolation_in_sql'

RSpec.describe RuboCop::Cop::Queries::DateInterpolationInSql, :config do
  include RuboCop::RSpec::ExpectOffense

  let(:msg) { described_class::MSG }

  context 'with a date interpolated into a SQL string' do
    it 'flags a date variable in a where string (jsonb key case)' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        universe.members.where("pit_enrollments ? '#{pit_date}'")
                                                   ^^^^^^^^^^^ %{msg}
      RUBY
    end

    it 'flags a date variable in a comparison' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        scope.where("EntryDate <= '#{report_end_date}'")
                                   ^^^^^^^^^^^^^^^^^^ %{msg}
      RUBY
    end

    it 'flags a date method call' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        scope.where("d = '#{enrollment.entry_date}'")
                          ^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
      RUBY
    end

    it 'flags a _at column value' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        scope.where("x = '#{updated_at}'")
                          ^^^^^^^^^^^^^ %{msg}
      RUBY
    end

    it 'flags Arel.sql with an interpolated date' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        scope.where(Arel.sql("d = '#{some_date}'"))
                                   ^^^^^^^^^^^^ %{msg}
      RUBY
    end

    it 'flags execute with an interpolated date' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        connection.execute("select '#{pit_date}'")
                                    ^^^^^^^^^^^ %{msg}
      RUBY
    end

    it 'flags a heredoc SQL string assigned to a local variable then passed to where' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        def q(pit_date)
          query = "pit_enrollments ? '#{pit_date}'"
                                      ^^^^^^^^^^^ %{msg}
          universe.members.where(query)
        end
      RUBY
    end

    it 'flags an explicit .to_s (the canonical human-format bug)' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        scope.where("d = '#{report_date.to_s}'")
                          ^^^^^^^^^^^^^^^^^^^ %{msg}
      RUBY
    end

    it 'flags a bare .to_fs (renders the app human format, not a machine format)' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        scope.where("d = '#{report_date.to_fs}'")
                          ^^^^^^^^^^^^^^^^^^^^ %{msg}
      RUBY
    end

    it 'flags .to_fs with a human format key' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        scope.where("d = '#{report_date.to_fs(:long)}'")
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
      RUBY
    end

    it 'flags find_by_sql with an interpolated date' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        scope.find_by_sql("d = '#{pit_date}'")
                                ^^^^^^^^^^^ %{msg}
      RUBY
    end

    it 'flags sanitize_sql_for_assignment with an interpolated date' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        sanitize_sql_for_assignment("d = '#{pit_date}'")
                                          ^^^^^^^^^^^ %{msg}
      RUBY
    end

    it 'flags a _timestamp column value' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        scope.where("t = '#{created_timestamp}'")
                          ^^^^^^^^^^^^^^^^^^^^ %{msg}
      RUBY
    end

    it 'flags a bare today' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        scope.where("t = '#{today}'")
                          ^^^^^^^^ %{msg}
      RUBY
    end

    it 'flags a _on column value' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        scope.where("d = '#{signed_on}'")
                          ^^^^^^^^^^^^ %{msg}
      RUBY
    end

    it 'flags a date-named lvar when any reaching assignment is a raw Date (wrong assignment must not win)' do
      expect_offense(<<~'RUBY', msg: described_class::MSG)
        def q(cond)
          filter_date = Date.current
          filter_date = conn.quote(filter_date) if cond
          scope.where("d = '#{filter_date}'")
                            ^^^^^^^^^^^^^^ %{msg}
        end
      RUBY
    end
  end

  context 'when the date is explicitly formatted (safe)' do
    it 'does not flag .iso8601' do
      expect_no_offenses(<<~'RUBY')
        universe.members.where("pit_enrollments ? '#{pit_date.iso8601}'")
      RUBY
    end

    it 'does not flag .strftime' do
      expect_no_offenses(<<~'RUBY')
        scope.where("d = '#{report_date.strftime('%Y-%m-%d')}'")
      RUBY
    end

    it 'does not flag .to_fs(:db)' do
      expect_no_offenses(<<~'RUBY')
        scope.where("d = '#{report_date.to_fs(:db)}'")
      RUBY
    end

    it 'does not flag .to_fs(:number)' do
      expect_no_offenses(<<~'RUBY')
        scope.where("d = '#{report_date.to_fs(:number)}'")
      RUBY
    end
  end

  context 'with SQL fragments that only look date-ish (safe)' do
    it 'does not flag an Arel column reference via .to_sql' do
      expect_no_offenses(<<~'RUBY')
        scope.where(Arel.sql("#{arel_table[:cha_updated_at].to_sql} + INTERVAL '1 year'"))
      RUBY
    end

    it 'does not flag adapter .quote' do
      expect_no_offenses(<<~'RUBY')
        scope.where("d = #{connection.quote(some_date)}")
      RUBY
    end

    it 'does not flag a date-named local variable that holds a SQL heredoc' do
      expect_no_offenses(<<~'RUBY')
        def q
          anniversary_date = <<~SQL
            make_date(2025, 1, 1)
          SQL
          scope.where(Arel.sql("earliest > #{anniversary_date}"))
        end
      RUBY
    end

    it 'does not flag "update"/"updates" (contains the substring "date")' do
      expect_no_offenses(<<~'RUBY')
        scope.where("UPDATE t SET x = #{updates.join(', ')}")
      RUBY
    end

    it 'does not flag a quoted-table-name via update_base' do
      expect_no_offenses(<<~'RUBY')
        conn.execute("UPDATE #{update_base.quoted_table_name} SET x = NULL")
      RUBY
    end

    it 'does not flag a local variable assigned from connection.quote' do
      expect_no_offenses(<<~'RUBY')
        def q
          deleted_at = conn.quote(Time.current)
          conn.execute("UPDATE t SET \"DateDeleted\" = #{deleted_at}")
        end
      RUBY
    end

    it 'does not flag a quoted lvar referenced inside a nested block' do
      expect_no_offenses(<<~'RUBY')
        def q
          deleted_at = conn.quote(Time.current)
          with_temp(conn) do |tmp|
            loop do
              conn.execute("UPDATE t SET x = #{deleted_at}")
            end
          end
        end
      RUBY
    end
  end

  context 'with non-date interpolations (safe)' do
    it 'does not flag an id' do
      expect_no_offenses(<<~'RUBY')
        scope.where("agency_id = #{agency.id}")
      RUBY
    end

    it 'does not flag a quoted table name' do
      expect_no_offenses(<<~'RUBY')
        scope.where("#{quoted_table_name}.name = 'x'")
      RUBY
    end
  end

  context 'with safe query forms' do
    it 'does not flag a bind parameter' do
      expect_no_offenses(<<~RUBY)
        scope.where('created_at > ?', date)
      RUBY
    end

    it 'does not flag the hash form' do
      expect_no_offenses(<<~RUBY)
        scope.where(created_at: date)
      RUBY
    end

    it 'does not flag interpolation outside a SQL context' do
      expect_no_offenses(<<~'RUBY')
        logger.info("processed as of #{pit_date}")
      RUBY
    end
  end
end
