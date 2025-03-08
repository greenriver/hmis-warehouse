
# frozen_string_literal: true

class CreateAnalyticsCohortClientData < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.cohort_client_data'
  end
end
