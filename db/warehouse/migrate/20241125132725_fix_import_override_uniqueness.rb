###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class FixImportOverrideUniqueness < ActiveRecord::Migration[7.0]
  def up
    # Remove uniqueness constraint so we can delete duplicates
    safety_assured do
      execute <<-SQL
        DROP INDEX uidx_import_overrides_rules;
      SQL
    end
  end
end
