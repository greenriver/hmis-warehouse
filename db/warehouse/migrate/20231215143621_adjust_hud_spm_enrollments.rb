class AdjustHudSpmEnrollments < ActiveRecord::Migration[6.1]
  TABLE = :hud_report_spm_enrollments

  INCOME_FIELDS = [
    :previous_earned_income,
    :previous_non_employment_income,
    :previous_total_income,
    :current_earned_income,
    :current_non_employment_income,
    :current_total_income,
  ].freeze

  def up
    safety_assured do
      # match income benefits type
      INCOME_FIELDS.each do |field|
        change_column TABLE, field, :numeric
      end
      remove_index TABLE, :previous_income_benefits_id
      remove_index TABLE, :current_income_benefits_id
    end
  end

  def down
    safety_assured do
      INCOME_FIELDS.each do |field|
        change_column TABLE, field, :integer
      end
      add_index TABLE, :previous_income_benefits_id
      add_index TABLE, :current_income_benefits_id
    end
  end
end
