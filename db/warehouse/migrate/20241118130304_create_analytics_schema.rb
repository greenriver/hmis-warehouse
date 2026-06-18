###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateAnalyticsSchema < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      execute 'CREATE SCHEMA analytics'
    end
  end

  def down
    safety_assured do
      execute 'DROP SCHEMA analytics CASCADE'
    end
  end
end
