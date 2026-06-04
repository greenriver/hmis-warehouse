# frozen_string_literal: true

###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The nightly_census_by_projects_id_seq sequence may still be typed as
# integer even though the id column is bigint. This migration fixes
# the sequence unconditionally (a no-op if already bigint) and skips the column
# ALTER only when the column is already bigint, avoiding an unnecessary table rewrite.
class FixNightlyCensusByProjectsIdSequence < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      execute 'ALTER TABLE public.nightly_census_by_projects ALTER COLUMN id TYPE bigint;' unless column_bigint?('nightly_census_by_projects', 'id')

      # Fix the sequence type
      execute 'ALTER SEQUENCE public.nightly_census_by_projects_id_seq AS bigint;'
    end
  end

  private

  def column_bigint?(table, column)
    result = execute(<<~SQL)
      SELECT data_type
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = #{connection.quote(table)}
        AND column_name = #{connection.quote(column)}
    SQL
    result.first&.fetch('data_type') == 'bigint'
  end
end
