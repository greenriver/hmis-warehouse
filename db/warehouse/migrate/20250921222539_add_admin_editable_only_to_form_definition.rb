###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddAdminEditableOnlyToFormDefinition < ActiveRecord::Migration[7.0]
  def change
    add_column :hmis_form_definitions, :admin_editable_only, :boolean, default: false
  end
end
