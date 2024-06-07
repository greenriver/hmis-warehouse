class MakeFormProcessorAssessmentOptional < ActiveRecord::Migration[7.0]
  # rails db:migrate:up:warehouse VERSION=20240603185124
  # rails db:migrate:down:warehouse VERSION=20240603185124
  def change
    change_column_null :hmis_form_processors, :custom_assessment_id, true
  end
end
