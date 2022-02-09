###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class EmploymentEducation < Base
    include HudSharedScopes
    include ::HMIS::Structure::EmploymentEducation
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = 'EmploymentEducation'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :employment_educations, optional: true
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_employment_educations, optional: true
    has_one :client, through: :enrollment, inverse_of: :employment_educations
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :employment_educations, optional: true
    has_one :project, through: :enrollment
    belongs_to :data_source

    def self.related_item_keys
      [
        :PersonalID,
        :EnrollmentID,
      ]
    end

  end
end
