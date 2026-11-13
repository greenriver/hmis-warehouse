###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDefaultToServiceSourceOnHopwaCaperServices < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      # remove default value in 8395
      change_column_default :hopwa_caper_services, :service_source, from: nil, to: 'hud_service'
    end
  end
end
