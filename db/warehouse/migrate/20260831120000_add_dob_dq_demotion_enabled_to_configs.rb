###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDOBDqDemotionEnabledToConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :configs, :dob_dq_demotion_enabled, :boolean, default: false, null: false
  end
end
