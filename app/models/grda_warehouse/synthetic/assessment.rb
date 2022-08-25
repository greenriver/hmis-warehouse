###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Synthetic
  class Assessment < GrdaWarehouseBase
    self.table_name = 'synthetic_assessments'

    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', optional: true
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    belongs_to :source, polymorphic: true, optional: true
    belongs_to :hud_assessment, class_name: 'GrdaWarehouse::Hud::Assessment', optional: true, primary_key: :hud_assessment_assessment_id, foreign_key: :AssessmentID

    validates_presence_of :enrollment
    validates_presence_of :client

    # Subclasses must define:
    #   assessment_date, assessment_type, assessment_level, prioritization_status, data_source

    # Subclasses may override
    def assessment_location
      'Unknown'
    end
    alias AssessmentLocation assessment_location

    def self.hud_sync
      # Import synthetic events
      GrdaWarehouse::Synthetic.available_assessment_types.each do |class_name|
        class_name.constantize.sync
      end

      create_hud_assessments

      # Clean up orphans in HUD table
      GrdaWarehouse::Hud::Assessment.
        where(synthetic: true).
        where.not(AssessmentID: select(:hud_assessment_assessment_id)).
        delete_all
    end

    def self.create_hud_assessments
      preload(:enrollment, :client, :source).find_in_batches do |batch|
        to_import = batch.map(&:hud_assessment_hash)
        assessment_source.import(
          to_import.compact,
          on_duplicate_key_update: {
            conflict_target: ['"AssessmentID"', :data_source_id],
            columns: assessment_source.hmis_configuration(version: '2022').keys,
          },
        )
        batch.each.with_index do |synthetic, i|
          added = to_import[i]
          next if added.blank?

          synthetic.update(hud_assessment_assessment_id: added[:AssessmentID])
        end
      end
    end

    def hud_assessment_hash
      return nil unless enrollment.present? &&
        source.present? &&
        assessment_date.present? &&
        assessment_location.present? &&
        assessment_type.present? &&
        assessment_level.present? &&
        prioritization_status.present?

      unique_key = [enrollment.EnrollmentID, enrollment.PersonalID, assessment_date, enrollment.data_source_id, source.id]
      assessment_id = hud_assessment&.AssessmentID || Digest::MD5.hexdigest(unique_key.join('_'))
      {
        AssessmentID: assessment_id,
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: enrollment.PersonalID,
        AssessmentDate: assessment_date,
        AssessmentLocation: assessment_location,
        AssessmentType: assessment_type,
        AssessmentLevel: assessment_level,
        PrioritizationStatus: prioritization_status,
        DateCreated: source.created_at,
        DateUpdated: source.updated_at,
        UserID: user_id,
        data_source_id: enrollment.data_source_id,
        synthetic: true,
      }
    end

    private def user_id
      @user_id ||= User.setup_system_user.name
    end

    def self.assessment_source
      GrdaWarehouse::Hud::Assessment
    end
  end
end
