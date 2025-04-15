# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class AssessmentResult < Base
    include HudSharedScopes
    include ::HmisStructure::AssessmentResult
    include ::HmisStructure::Shared
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = :AssessmentResults
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to_with_composite_keys :export, class_name: 'GrdaWarehouse::Hud::Export', keys: [:ExportID], inverse_of: :assessment_results, optional: true
    belongs_to_with_composite_keys :assessment, class_name: 'GrdaWarehouse::Hud::Assessment', keys: [:AssessmentID], optional: true
    belongs_to_with_composite_keys :direct_enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', keys: [:EnrollmentID, :PersonalID], optional: true # Assuming hud_enrollment_belongs
    belongs_to_with_composite_keys :direct_client, class_name: 'GrdaWarehouse::Hud::Client', keys: [:PersonalID], optional: true
    belongs_to_with_composite_keys :user, class_name: 'GrdaWarehouse::Hud::User', keys: [:UserID], inverse_of: :assessment_results, optional: true
    belongs_to :data_source
    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to_with_composite_keys :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', keys: [:EnrollmentID, :PersonalID], optional: true
    belongs_to_with_composite_keys :assessment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Assessment', keys: [:AssessmentID, :PersonalID], optional: true

    has_one :enrollment, through: :assessment
    has_one :client, through: :assessment, inverse_of: :assessment_results
  end
end
