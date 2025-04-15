# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class EmploymentEducation < Base
    include HudSharedScopes
    include ::HmisStructure::EmploymentEducation
    include ::HmisStructure::Shared
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = 'EmploymentEducation'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to_with_composite_keys :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', keys: [:EnrollmentID, :PersonalID], inverse_of: :employment_educations, optional: true
    belongs_to_with_composite_keys :direct_client, class_name: 'GrdaWarehouse::Hud::Client', keys: [:PersonalID], inverse_of: :direct_employment_educations, optional: true
    belongs_to_with_composite_keys :export, class_name: 'GrdaWarehouse::Hud::Export', keys: [:ExportID], inverse_of: :employment_educations, optional: true
    belongs_to_with_composite_keys :user, class_name: 'GrdaWarehouse::Hud::User', keys: [:UserID], inverse_of: :employment_educations, optional: true
    belongs_to :data_source
    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to_with_composite_keys :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', keys: [:EnrollmentID, :PersonalID], optional: true

    has_one :project, through: :enrollment
    has_one :client, through: :enrollment, inverse_of: :employment_educations

    def self.related_item_keys
      [
        :PersonalID,
        :EnrollmentID,
      ]
    end
  end
end
