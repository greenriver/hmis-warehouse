###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UpdateCeReferralNote < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      # replace jsonb with unstructured text content
      remove_column :ce_referral_notes, :submitted_form_data, :jsonb
      add_column :ce_referral_notes, :note, :text, null: true

      # add optional reference to wfe_step to track whether the note is associated with a particular step
      add_reference :ce_referral_notes, :wfe_step, foreign_key: true, null: true
    end
  end
end

# rails db:migrate:up:warehouse VERSION=20250701185134
# rails db:migrate:down:warehouse VERSION=20250701185134
