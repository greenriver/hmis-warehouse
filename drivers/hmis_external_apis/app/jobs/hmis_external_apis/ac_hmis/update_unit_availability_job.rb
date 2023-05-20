###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class UpdateUnitAvailabilityJob < ApplicationJob
    include HmisExternalApis::AcHmis::ReferralJobMixin

    # determine current capacity at project and update external system
    # @param project_id [Integer]
    # @param unit_type_id [Integer]
    # @param requested_by [String]
    def perform(project_id:, unit_type_id:, requested_by:)
      project = Hmis::Hud::Project.find(project_id)
      project_mper_id = mper.identify_source(project)
      raise "mper id for not found Hmis::Hud::Project##{project_id}" unless project_mper_id

      unit_type = Hmis::UnitType.find(unit_type_id)
      unit_type_mper_id = mper.identify_source(unit_type)
      raise "mper id for not found for Hmis::UnitType##{unit_type_id}" unless unit_type_mper_id

      # FIXME: technically should synchronize these queries
      total = project.units.where(unit_type: unit_type).count
      assigned = project.units.where(unit_type: unit_type)
        .joins(:unit_occupancies)
        .merge(Hmis::UnitOccupancy.active)
        .count('distinct(hmis_units.id)')

      available = total - assigned
      raise "Unexpected unit availability: project:#{project_id}, unit:#{unit_type_id}, #{total}-#{assigned}" if available < 0

      payload = {
        program_id: project_mper_id,
        unit_type_id: unit_type_mper_id,
        available_units: available,
        requested_by: requested_by,
      }
      link.update_unit_capacity(payload)
    end
  end
end
