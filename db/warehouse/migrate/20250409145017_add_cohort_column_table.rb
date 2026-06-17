###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddCohortColumnTable < ActiveRecord::Migration[7.0]
  def change
    create_table :cohort_columns do |t|
      t.string :class_name, unique: true
      t.boolean :active, default: true
    end
  end
end
