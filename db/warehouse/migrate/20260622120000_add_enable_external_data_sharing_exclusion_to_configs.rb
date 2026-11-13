###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddEnableExternalDataSharingExclusionToConfigs < ActiveRecord::Migration[7.2]
  def change
    add_column :configs, :enable_external_data_sharing_exclusion, :boolean, default: false, null: false
  end
end
