# frozen_string_literal: true

class CreateAnalyticsEvents < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.events'
  end
end
