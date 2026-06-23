###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddIndexes < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_index :medications, :patient_id
    end
  end
end
