class AddReviewOnlyScorecardFields < ActiveRecord::Migration[5.2]
  def change
    change_table :project_scorecard_reports do |t|
      t.string :site_monitoring

      t.integer :total_ces_referrals
      t.integer :accepted_ces_referrals

      t.integer :clients_with_vispdats
      t.integer :average_vispdat_score
    end
  end
end
