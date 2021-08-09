class FixForBadDeploy < ActiveRecord::Migration[5.2]
  def up
    change_table :synthetic_assessments do |t|
      unless t.column_exists?(:hud_assessment_id)
        t.references :hud_assessment
      end

    end
  end
end
