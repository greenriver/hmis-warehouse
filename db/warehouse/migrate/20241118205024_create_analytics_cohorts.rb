# frozen_string_literal: true

class CreateAnalyticsCohorts < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.cohorts'
  end
end
