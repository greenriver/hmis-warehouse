class CreateAnalyticsCoCCodes < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.coc_codes'
  end
end
