# frozen_string_literal: true

class CreateAnalyticsCohortColumnMetadata < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.cohort_column_metadata'
  end
end
