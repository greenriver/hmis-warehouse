class CreateAnalyticsIncomeBenefits < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.income_benefits'
  end
end
