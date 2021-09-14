###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Assessment < Base
    include HudSharedScopes
    include ::HMIS::Structure::Assessment
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = :Assessment
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :assessments, optional: true
    belongs_to :enrollment, **hud_enrollment_belongs
    has_one :client, through: :enrollment, inverse_of: :assessments
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client')
    belongs_to :data_source
    has_many :assessment_questions, **hud_assoc(:AssessmentID, 'AssessmentQuestion')
    has_many :assessment_results, **hud_assoc(:AssessmentID, 'AssessmentResult')

    scope :within_range, ->(range) do
      # convert the range into a standard range for backwards compatability
      range = (range.start..range.end) if range.is_a?(::Filters::DateRange)
      where(AssessmentDate: range)
    end

    scope :importable, -> do
      where(synthetic: false)
    end

    scope :synthetic, -> do
      where(synthetic: true)
    end
  end
end
