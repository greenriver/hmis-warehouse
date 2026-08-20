###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddTimestampsToConfigs < ActiveRecord::Migration[8.1]
  def up
    add_column :configs, :created_at, :datetime
    add_column :configs, :updated_at, :datetime

    safety_assured do
      execute(<<~SQL)
        UPDATE configs
        SET created_at = NOW(), updated_at = NOW()
        WHERE created_at IS NULL
      SQL
    end
  end

  def down
    remove_column :configs, :created_at
    remove_column :configs, :updated_at
  end
end
