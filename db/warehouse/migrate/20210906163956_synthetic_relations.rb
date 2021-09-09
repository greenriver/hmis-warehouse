class SyntheticRelations < ActiveRecord::Migration[5.2]
  def change
    remove_column :synthetic_assessments, :hud_assessment_id, :integer, index: true
    remove_column :synthetic_events, :hud_event_id, :integer, index: true
    add_column :synthetic_assessments, :hud_assessment_assessment_id, :string, index: true
    add_column :synthetic_events, :hud_event_event_id, :string, index: true
  end
end
