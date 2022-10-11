class AddSpmIdToScorecard < ActiveRecord::Migration[6.1]
  def change
    add_column :project_scorecard_reports, :spm_id, :integer
  end
end
