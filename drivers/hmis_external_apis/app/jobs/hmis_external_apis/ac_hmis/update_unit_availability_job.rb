###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class UpdateUnitAvailabilityJob < ApplicationJob
    include HmisExternalApis::AcHmis::ReferralJobMixin

    JOB_LOCK_NAME = 'hmis_external_update_unit_availability'.freeze

    # @param data_source_id [Integer]
    # @param force [Boolean]
    def perform(data_source_id:)
      with_locks do
        projects = Hmis::Hud::Project.where(data_source_id: data_source_id)
        projects.find_each do |project|
          project.external_unit_availability_syncs.dirty.preload(:unit_type, :user).each do |sync|
            # sync.user made the most recent user changes, either to occupancy or unit inventory
            sync_project_unit_type(project: project, unit_type: sync.unit_type, user: sync.user)
            # track sync version
            sync.update!(synced_version: sync.local_version)
          end
        end
      end
    end

    protected

    def with_locks
      # lock job specific lock to prevent overlapping runs
      Hmis::HmisBase.with_advisory_lock(JOB_LOCK_NAME, timeout_seconds: 0) do
        # lock to synchronize with the project importer which may change available units
        Hmis::HmisBase.with_advisory_lock(
          HmisExternalApis::AcHmis::Importers::ProjectsImporter::JOB_LOCK_NAME,
          timeout_seconds: 0,
          shared: true,
        ) do
          yield
          # FIXME ideally should report to dead man's snitch or equiv
        end
      end
    end

    # determine current capacity at project and update external system
    # @param project [Hmis::Hud::Project]
    # @param unit_type [Hmis::UnitType]
    # @param user [Hmis::User]
    def sync_project_unit_type(project:, unit_type:, user:)
      project_mper_id = mper.identify_source(project)
      raise "mper id not found Hmis::Hud::Project##{project.id}" unless project_mper_id

      unit_type_mper_id = mper.identify_source(unit_type)
      raise "mper id not found for Hmis::UnitType##{unit_type.id}" unless unit_type_mper_id

      capacity, assigned = query_capacity(project, unit_type)

      available_units = capacity - assigned
      unless available_units.between?(0, 10_000)
        # alert and skip sync for invalid values"
        msg = "Unit availability out of bounds for Hmis::Hud::Project#:#{project.id}, Hmis::UnitType:#{unit_type.id}. Capacity: #{capacity}, assigned:#{assigned}"
        Sentry.capture_message(msg)
        return
      end

      user ||= Hmis::User.system_user
      payload = {
        program_id: project_mper_id,
        unit_type_id: unit_type_mper_id,
        available_units: available_units,
        capacity: capacity,
        requested_by: format_requested_by(user.email),
      }
      link.update_unit_capacity(payload)
    end

    def query_capacity(project, unit_type)
      project_unit_scope = project.units.where(unit_type: unit_type)
      # ideally this would be one query to eliminate the possibility of inconsistent reads
      total = project.units.where(unit_type: unit_type).count
      assigned = project.units.where(unit_type: unit_type)
        .joins(:unit_occupancies)
        .merge(Hmis::UnitOccupancy.active)
        .count('distinct(hmis_units.id)')
      [total, assigned]
    end
  end
end
