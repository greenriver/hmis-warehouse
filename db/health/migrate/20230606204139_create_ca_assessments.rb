###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateCaAssessments < ActiveRecord::Migration[6.1]
  def change
    create_table :ca_assessments do |t|
      t.references :patient
      t.references :instrument, polymorphic: true

      t.timestamps
    end
  end
end
