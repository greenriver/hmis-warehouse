# frozen_string_literal: true

class CreateAnalyticsCohortClientTabs < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.cohort_client_tabs'
  end
end
