class AddSpmToScorecard < ActiveRecord::Migration[5.2]
  def change
    add_reference :project_scorecard_reports, :spm
  end
end
