class AddQuestionStatusColumnsToReportIntanct < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_instances, :build_for_questions, :jsonb
    add_column :hud_report_instances, :remaining_questions, :jsonb
  end
end
