###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddToFormSubmission < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_reference :hmis_external_form_submissions, :enrollment, index: true, null: true
    end
  end
end
