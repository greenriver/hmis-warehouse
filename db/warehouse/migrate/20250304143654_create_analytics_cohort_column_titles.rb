class CreateAnalyticsCohortColumnTitles < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.cohort_column_titles'
  end
end
