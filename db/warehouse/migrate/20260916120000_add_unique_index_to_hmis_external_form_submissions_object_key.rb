###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Prevents two concurrent ConsumeExternalFormSubmissionsJob workers from inserting duplicates.
class AddUniqueIndexToHmisExternalFormSubmissionsObjectKey < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      add_index :hmis_external_form_submissions, :object_key, unique: true
    end
  end
end
