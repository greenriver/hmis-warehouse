###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateMhxMedicaidIdResponses < ActiveRecord::Migration[6.1]
  def change
    create_table :mhx_medicaid_id_responses do |t|
      t.references :medicaid_id_inquiry
      t.string :response

      t.timestamps
    end
  end
end
