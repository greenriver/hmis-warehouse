# frozen_string_literal: true

class CreateAnalyticsLookupsLivingSituations < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.lookups_living_situations'
  end
end
