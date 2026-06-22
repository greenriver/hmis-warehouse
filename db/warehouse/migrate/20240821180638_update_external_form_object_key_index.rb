###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UpdateExternalFormObjectKeyIndex < ActiveRecord::Migration[7.0]
  def change
    remove_index :hmis_form_definitions, column: :external_form_object_key
  end
end
