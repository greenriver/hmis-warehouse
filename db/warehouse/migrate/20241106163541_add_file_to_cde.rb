#  Copyright 2016 - 2025 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class AddFileToCde < ActiveRecord::Migration[7.0]
  def change
    # use safety_assured (ignore StrongMigrations) here because validating a column full of nulls should still be fast
    safety_assured do
      add_reference :CustomDataElements, :value_file, null: true, foreign_key: { to_table: :files }
    end
  end
end
