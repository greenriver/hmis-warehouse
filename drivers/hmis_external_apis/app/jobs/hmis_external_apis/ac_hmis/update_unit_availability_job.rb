###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class UpdateUnitAvailabilityJob < BaseJob
    queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)
    include HmisExternalApis::AcHmis::ReferralJobMixin
    include NotifierConfig

    JOB_LOCK_NAME = 'hmis_external_update_unit_availability'.freeze

    # @param force [Boolean]
    def perform(force: false)
      return unless HmisExternalApis::AcHmis::LinkApi.enabled?

      setup_notifier(self.class.name)

      data_source = HmisExternalApis::AcHmis.data_source
      projects = Hmis::Hud::Project.where(data_source: data_source)
      failed_updates = 0
      with_locks do
        projects.find_each do |project|
          force_update(project) if force
          project.external_unit_availability_syncs.dirty.preload(:unit_type, :user).each do |sync|
            # sync.user made the most recent user changes, either to occupancy or unit inventory
            sync_project_unit_type(
              project: project,
              unit_type: sync.unit_type,
              user: sync.user || default_user,
            )
            # track sync version
            sync.update!(synced_version: sync.local_version)
          rescue HmisErrors::ApiError
            # The error body itself already gets sent to Sentry from the LinkApi. Here, just count the # of failures.
            failed_updates += 1
          end
        end
      end

      handle_alert("Failed to sync #{failed_updates} capacity updates to LINK.") if failed_updates.positive?
      # If changes were tracked during processing, requeue job
      # FIXME: this check should no longer be necessary once we move to a cron job
      requeue_job if local_changes?(projects)
    end

    protected

    def handle_alert(message)
      Sentry.capture_message(message)
      @notifier.ping(message)
    end

    def default_user
      @default_user ||= Hmis::User.system_user
    end

    def force_update(project)
      unit_type_ids = project.units.distinct.pluck(:unit_type_id).compact
      unit_type_ids.each do |unit_type_id|
        HmisExternalApis::AcHmis::UnitAvailabilitySync.upsert_or_bump_version(
          project_id: project.id,
          user_id: default_user.id,
          unit_type_id: unit_type_id,
        )
      end
    end

    def requeue_job
      HmisExternalApis::AcHmis::UpdateUnitAvailabilityJob.perform_later
    end

    def local_changes?(projects)
      HmisExternalApis::AcHmis::UnitAvailabilitySync.
        joins(:project).
        merge(projects).
        dirty.
        any?
    end

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

      unit_type_mper_id = mper.identify_source(unit_type)
      unless unit_type_mper_id
        handle_alert("mper id not found for Hmis::UnitType##{unit_type.id}")
        return
      end

      capacity, assigned = query_capacity(project, unit_type)

      available_units = capacity - assigned
      unless available_units.between?(0, 10_000)
        # alert and skip sync for invalid values"
        handle_alert("unit availability out of bounds for Hmis::Hud::Project#:#{project.id}, Hmis::UnitType:#{unit_type.id}. Capacity: #{capacity}, assigned:#{assigned}")
        return
      end

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
      # ideally this would be one query to eliminate the possibility of inconsistent reads
      total = project.units.where(unit_type: unit_type).count
      assigned = project.units.where(unit_type: unit_type).
        joins(:unit_occupancies).
        merge(Hmis::UnitOccupancy.active).
        count('distinct(hmis_units.id)')
      [total, assigned]
    end
  end
end
