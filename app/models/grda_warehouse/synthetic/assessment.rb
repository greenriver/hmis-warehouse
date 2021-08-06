###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Synthetic
  class Assessment < GrdaWarehouseBase
    self.table_name = 'synthetic_assessments'

    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment'
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :source, polymorphic: true
    belongs_to :hud_assessment, class_name: 'GrdaWarehouse::Hud::Assessment', optional: true

    validates_presence_of :enrollment
    validates_presence_of :client

    # Subclasses must define:
    #   assessment_date, assessment_type, assessment_level, prioritization_status, data_source

    # Subclasses may override
    def assessment_location
      ''
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
        where.not(id: select(:hud_assessment_id)).
        delete_all
    end

    def self.create_hud_assessments
      preload(:enrollment, :client, :source).find_in_batches do |batch|
        assessment_source.import(
          batch.map(&:hud_assessment_hash),
          on_duplicate_key_update: {
            conflict_target: ['"AssessmentID"', :data_source_id],
            columns: assessment_source.hmis_configuration.keys,
          },
        )
      end
    end

    def hud_assessment_hash
      {
        AssessmentID: hud_assessment&.AssessmentID || SecureRandom.uuid.gsub(/-/, ''),
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: client.PersonalID,
        AssessmentDate: assessment_date,
        AssessmentLocation: assessment_location,
        AssessmentType: assessment_type,
        AssessmentLevel: assessment_level,
        PrioritizationStatus: prioritization_status,
        DateCreated: source.created_at,
        DateUpdated: source.updated_at,
        UserID: user_id,
        data_source_id: ds.id,
        synthetic: true,
      }
    end

    private def user_id
      @user_id ||= User.setup_system_user.name
    end

    private def ds
      @ds ||= GrdaWarehouse::DataSource.where(short_name: data_source).first_or_create do |ds|
        ds.name = data_source
        ds.authoritative = true
        ds.authoritative_type = :synthetic
      end
    end

    def self.assessment_source
      GrdaWarehouse::Hud::Assessment
    end
  end
end
