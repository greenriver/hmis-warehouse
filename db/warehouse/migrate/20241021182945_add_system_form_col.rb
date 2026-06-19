###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddSystemFormCol < ActiveRecord::Migration[7.0]
  def change
    add_column :hmis_form_definitions, :managed_in_version_control, :boolean, default: false
  end
end
