###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class YouthEducationStatus < Base
    include HudSharedScopes
    include ::HMIS::Structure::YouthEducationStatus
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = :YouthEducationStatus
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :youth_education_statuses, optional: true
    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :youth_education_statuses, optional: true
    has_one :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_youth_education_statuses
    has_one :client, through: :enrollment, inverse_of: :youth_education_statuses
    belongs_to :data_source, optional: true
  end
end
