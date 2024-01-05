class BackfillHmisPostExitAssessments < ActiveRecord::Migration[6.1]
  # Create what we call 'synthetic' post-exit assessments for exit-assessments that collected r20 attributes
  def up
    post_exit_data_collection_stage = 6
    exit_data_collection_stage = 3
    post_exit_definition = Hmis::Form::Definition.where(identifier: 'base-post_exit').first!

    # skip exits that already have post-exit assessments
    post_exit_ids = Hmis::Hud::CustomAssessment.
      where(DataCollectionStage: post_exit_data_collection_stage).
      joins(:form_processor).
      pluck(:exit_id)

    exit_assessments = Hmis::Hud::CustomAssessment.
      where(data_collection_stage: exit_data_collection_stage).
      joins(enrollment: :exit).
      where(Hmis::Hud::Exit.arel_table['id'].not_in(post_exit_ids)).
      preload(:form_processor).
      preload(enrollment: :exit)

    exit_assessments.find_each do |exit_assessment|
      exit = exit_assessment.enrollment.exit
      exit_form_processor = exit_assessment.form_processor
      r20_values = (exit_form_processor&.values || {}).slice("R20.1", "R20.2", "R20.1.methods")
      r20_hud_values = (exit_form_processor&.hud_values || {}).slice("Exit.aftercareDate", "Exit.aftercareMethods", "Exit.aftercareProvided")
      after_care_date = r20_values['R20.1'] || exit.AftercareDate&.to_s(:db)
      next unless after_care_date.present?

      post_exit_assessment_attrs = exit_assessment.attributes.slice(
        'EnrollmentID',
        'PersonalID',
        'data_source_id',
        'UserID',
        'DateCreated',
        'DateUpdated',
        'wip', # assume we want to copy wip assessments
      ).merge(
        'CustomAssessmentID' => Hmis::Hud::CustomAssessment.generate_uuid,
        'AssessmentDate' => after_care_date,
        'DataCollectionStage' => post_exit_data_collection_stage,
        'wip' => false,
      )
      post_exit_assessment = Hmis::Hud::CustomAssessment.new(post_exit_assessment_attrs)
      post_exit_assessment.build_form_processor(
        values: r20_values.merge("information-date-input" => after_care_date),
        hud_values: r20_hud_values.merge("assessmentDate" => after_care_date),
        exit_id: exit.id,
        definition_id: post_exit_definition.id,
      )
      post_exit_assessment.save!
      # Should we also trim r20 values out of exit_assessment.form_processor?
    end
  end

  # but don't allow dangerous rollback unless we are in development
  if Rails.env.development?
    def down
      Hmis::Hud::CustomAssessment.where(DataCollectionStage: 6).each(&:really_destroy!)
    end
  end
end
