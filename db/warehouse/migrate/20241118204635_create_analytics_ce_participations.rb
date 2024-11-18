class CreateAnalyticsCeParticipations < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.ce_participations'
  end
end
