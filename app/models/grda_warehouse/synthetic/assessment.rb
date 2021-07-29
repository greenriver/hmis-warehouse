###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
#
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

      #  Create HUD assessments from synthetic events
      find_each(&:hud_sync)

      # Clean up orphans in HUD table
      GrdaWarehouse::Hud::Assessment.
        where(synthetic: true).
        where.not(id: select(:hud_assessment_id)).
        delete_all
    end

    def hud_sync
      ds = GrdaWarehouse::DataSource.find_by(short_name: data_source)
      return unless ds.present?

      hud_assessment_hash = {
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: client.PersonalID,
        AssessmentDate: assessment_date,
        AssessmentLocation: assessment_location,
        AssessmentType: assessment_type,
        AssessmentLevel: assessment_level,
        PrioritizationStatus: prioritization_status,
        data_source_id: ds.id,
        synthetic: true,
      }

      if hud_assessment.nil?
        hud_assessment_hash[:AssessmentID] = SecureRandom.uuid.gsub(/-/, '')
        create_hud_assessment(hud_assessment_hash)
      else
        hud_assessment.update(hud_assessment_hash)
      end
    end
  end
end
