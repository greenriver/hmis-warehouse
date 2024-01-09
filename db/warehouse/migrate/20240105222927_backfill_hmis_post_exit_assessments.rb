class BackfillHmisPostExitAssessments < ActiveRecord::Migration[6.1]
  # Create what we call 'synthetic' post-exit assessments for exit-assessments that collected r20 attributes
  def up
    post_exit_data_collection_stage = 6
    ::HmisUtil::JsonForms.new.seed_assessment_form_definitions
    post_exit_definition = Hmis::Form::Definition.where(identifier: 'base-post_exit').first!

    # skip exits that already have post-exit assessments
    skip_exit_ids = Hmis::Hud::CustomAssessment.
      where(DataCollectionStage: post_exit_data_collection_stage).
      joins(:form_processor).
      pluck(:exit_id)

    exit_scope = Hmis::Hud::Exit.where.not(AftercareDate: nil).where.not(id: skip_exit_ids)

    exit_scope.find_each do |exit|
      after_care_date = exit.AftercareDate
      post_exit_assessment_attrs = exit.attributes.slice(
        'EnrollmentID',
        'PersonalID',
        'data_source_id',
        'UserID',
        'DateCreated',
        'DateUpdated',
      ).merge(
        assessment_date: after_care_date,
        wip: false,
        data_collection_stage: post_exit_data_collection_stage,
      )
      post_exit_assessment = Hmis::Hud::CustomAssessment.new(post_exit_assessment_attrs)
      post_exit_assessment.build_form_processor(exit: exit, definition: post_exit_definition)
      post_exit_assessment.save!
    end
  end

  # but don't allow dangerous rollback unless we are in development
  if Rails.env.development?
    def down
      Hmis::Hud::CustomAssessment.where(DataCollectionStage: 6).each(&:really_destroy!)
    end
  end
end
