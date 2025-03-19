# frozen_string_literal: true

class CreateCustomAssessmentAnswerLookups < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.custom_assessment_answer_lookups'
  end
end
