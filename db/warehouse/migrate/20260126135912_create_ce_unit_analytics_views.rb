###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateCeUnitAnalyticsViews < ActiveRecord::Migration[7.2]
  def change
    create_view 'analytics.hmis_units'
    create_view 'analytics.hmis_unit_types'
    create_view 'analytics.hmis_unit_groups'
    create_view 'analytics.hmis_unit_occupancy'
  end
end
