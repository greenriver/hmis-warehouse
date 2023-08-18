###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class UpdateUnitAvailabilityJob < ApplicationJob
    include HmisExternalApis::AcHmis::ReferralJobMixin

    # @param data_source_id [Integer]
    def perform(data_source_id:)
      # synchronize with the importer
      Hmis::HmisBase.with_advisory_lock(
        'hmis_project_importer',
        timeout_seconds: 0,
        shared: true
      ) do
        projects = Hmis::Hud::Project.where(data_source_id: data_source_id)
        projects.preload(:unit_type_mappings).find_each do |project|
          sync_project(project)
        end
      end
    end

    protected

    def sync_project(project)
      project.unit_type_mappings.each do |mapping|
        # capture time before query for the query to avoid timing issues
        now = DateTime.current
        change = project.with_lock do
          change_to_sync(project, mapping)
        end

        # do we need a sync?
        if change
          sync_project(project:, change:)
          mapping.update!(last_synced_at: now)
        end
      end
    end

    def change_to_sync(project, mapping)
      capacity = project.units.where(unit_type: unit_type).count
      assigned = project.units.where(unit_type: unit_type)
        .joins(:unit_occupancies)
        .merge(Hmis::UnitOccupancy.active)
        .count('distinct(hmis_units.id)')

      last_values =  mapping.last_synced_values || {}
      return if capacity == last_values['capacity'] && assigned == last_values['assigned']

      # FIXME: this is going to be inaccurate sometimes.
      # # Hmis::ActiveRange

      {
        capacity: capacity,
        assigned: assigned,
        user_id: user_id,
      }
    end


    # determine current capacity at project and update external system
    # @param project [Hmis::Hud::Project]
    # @param unit_type_id [Integer]
    # @param requested_by [String]
    def sync_project(project:, unit_type_id:, user_id:, capacity:, assigned:)
      project_mper_id = mper.identify_source(project)
      raise "mper id not found Hmis::Hud::Project##{project_id}" unless project_mper_id

      unit_type = Hmis::UnitType.find(unit_type_id)
      unit_type_mper_id = mper.identify_source(unit_type)
      raise "mper id not found for Hmis::UnitType##{unit_type_id}" unless unit_type_mper_id

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
        capacity: total,
        requested_by: format_requested_by(requested_by),
      }
      link.update_unit_capacity(payload)
    end
  end
end
