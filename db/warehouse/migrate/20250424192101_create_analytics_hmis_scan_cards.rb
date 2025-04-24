# frozen_string_literal: true

class CreateAnalyticsHmisScanCards < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.hmis_scan_cards'
  end
end
