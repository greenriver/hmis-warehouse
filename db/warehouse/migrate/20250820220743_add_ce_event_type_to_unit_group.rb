###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddCeEventTypeToUnitGroup < ActiveRecord::Migration[7.1]
  def change
    # Valid values are integers 1 through 18; see EventType enum
    add_column :hmis_unit_groups, :ce_event_type, :integer, null: true
  end
end

# rails db:migrate:up:warehouse VERSION=20250820220743 RAILS_ENV=development
# rails db:migrate:down:warehouse VERSION=20250820220743 RAILS_ENV=development
