###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class FixDisabledMhxImportConfigs < ActiveRecord::Migration[7.0]
  def up
    Health::ImportConfig.where(kind: 'disabled_medicaid_hmis_exchange').
      update_all(
        kind: 'medicaid_hmis_exchange',
        type: 'Health::ImportConfigSsh',
        active: false,
      )
  end
end
