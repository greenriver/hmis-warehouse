###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class SetImportConfigType < ActiveRecord::Migration[7.0]
  def change
    Health::ImportConfig.all.each do |config|
      case config.kind
      when 'medicaid_hmis_exchange'
        config.update(type: 'Health::ImportConfigSsh')
      else
        config.update(type: 'Health::ImportConfigPassword')
      end
    end
  end
end
