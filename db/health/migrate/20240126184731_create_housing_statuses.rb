###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateHousingStatuses < ActiveRecord::Migration[6.1]
  def change
    create_table :housing_statuses do |t|
      t.references :patient
      t.date :collected_on
      t.string :status
      t.timestamps
    end
  end
end
