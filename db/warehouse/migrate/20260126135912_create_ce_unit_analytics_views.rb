# frozen_string_literal: true

class CreateCeUnitAnalyticsViews < ActiveRecord::Migration[7.2]
  def change
    create_view 'analytics.hmis_units'
    create_view 'analytics.hmis_unit_types'
    create_view 'analytics.hmis_unit_groups'
    create_view 'analytics.hmis_unit_occupancy'
  end
end
