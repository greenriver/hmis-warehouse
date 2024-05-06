###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks
  class ProjectCleanup
    include ArelHelper
    include NotifierConfig

    attr_accessor :skip_location_cleanup
    def initialize(
      _bogus_notifier = false,
      project_ids: GrdaWarehouse::Hud::Project.select(:id),
      skip_location_cleanup: false,
      debug: false
    )
      setup_notifier('Project Cleaner')
      @project_ids = project_ids
      @debug = debug
      self.skip_location_cleanup = skip_location_cleanup
    end

    def run!
      @start_time = Time.current
      debug_log('Cleaning projects')
      @projects = load_projects

      invalidate_service_for_moved_projects
      @projects.each do |project|
        any_enrollments = project.enrollments.exists?

        if should_update_type?(project)
          fix_project_type(project)
        elsif homeless_mismatch?(project) && any_enrollments # if should_update_type? returned true, these have been fixed
          invalidate_enrollments(project)
        end

        fix_name(project)
        fix_client_locations(project) if any_enrollments
        remove_unneeded_hmis_participations(project)
      end
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.batch_process_unprocessed!(max_wait_seconds: 1_800)

      elapsed = Time.current - @start_time
      Rails.logger.tagged({ task_name: 'Project Cleaner', repeating_task: true, task_runtime: elapsed }) do
        Rails.logger.info('Project Cleanup Complete')
      end
    end

    def load_projects
      project_source.where(id: @project_ids).preload(:project_cocs)
    end

    def should_update_type? project
      sh_project_types_for_check = sh_project_types(project)
      project_types_match_sh_types = true
      # If SHE only has one set of project types, that's generally good, just confirm they match the project's types
      if sh_project_types_for_check.count == 1 # rubocop:disable Style/IfUnlessModifier
        project_types_match_sh_types = project.ProjectType == sh_project_types_for_check.first
      end
      # If SHE has more than one set of project types, we'll need to rebuild
      project_type_changed_in_source = sh_project_types_for_check.count > 1
      project_type_changed_in_source || ! project_types_match_sh_types
    end

    # Fix any SHE with incorrect project types
    def fix_project_type(project)
      debug_log("Updating type for #{project.ProjectName} << #{project.organization&.OrganizationName || 'unknown'} in #{project.data_source.short_name}... current ProjectType: #{project.ProjectType} project types in Service History:  #{sh_project_types(project).inspect}")

      # Force a rebuild of all related enrollments
      project_source.transaction do
        project.enrollments.invalidate_processing!
        # Fix the SHE with record_type "first"
        service_history_enrollment_source.where(
          project_id: project.ProjectID,
          data_source_id: project.data_source_id,
        ).update_all(project_type: project.ProjectType)
      end
      debug_log("done invalidating enrollments for #{project.ProjectName}")
    end

    def invalidate_service_for_moved_projects
      scope = GrdaWarehouse::ServiceHistoryEnrollment.left_outer_joins(:project).where(p_t[:id].eq(nil))
      invalid_count = scope.count
      return unless invalid_count.positive?

      debug_log("Found #{invalid_count} enrollments with missing projects, usually because the project was moved to a different organization, forcing rebuild")
      # This is hacky but we need to update the enrollment table
      GrdaWarehouse::Hud::Enrollment.joins(:service_history_enrollment).
        where(she_t[:id].in(Arel.sql(scope.select(:id).to_sql))).
        update_all(processed_as: nil)
      # delete all of the SHE since some of these would never get cleaned up otherwise
      # note: this means these won't be available in the app until the rebuild occurs
      scope.delete_all
    end

    def sh_project_types project
      service_history_enrollment_source.
        where(data_source_id: project.data_source_id, project_id: project.ProjectID).
        distinct.
        pluck(:project_type)
    end

    def should_update_name? project
      service_history_enrollment_source.
        where(data_source_id: project.data_source_id, project_id: project.ProjectID).
        where.not(project_name: project.ProjectName).exists?
    end

    def fix_name(project)
      return unless should_update_name?(project)

      debug_log("Updating name for #{project.ProjectName}")
      project_source.transaction do
        # Update any service records with this project
        service_history_enrollment_source.
          where(project_id: project.ProjectID, data_source_id: project.data_source_id).
          where.not(project_name: project.ProjectName).
          update_all(project_name: project.ProjectName)
      end
      debug_log("done updating name for #{project.ProjectName}")
    end

    # Just check the last two years for discrepancies to speed checking
    private def homeless_status_correct?(project)
      if HudUtility2024.homeless_project_types.include?(project.project_type)
        # ES, SO, SH, TH
        any_non_homeless_history = service_history_service_source.
          where(date: 2.years.ago..Date.current).
          joins(service_history_enrollment: :project).
          merge(project_source.where(id: project.id)).
          where.not(homeless: true).exists?
        !any_non_homeless_history
      else
        # PH, and all others
        any_homeless_history = service_history_service_source.
          where(date: 2.years.ago..Date.current).
          joins(service_history_enrollment: :project).
          merge(project_source.where(id: project.id)).
          where(homeless: true).exists?
        !any_homeless_history
      end
    end

    def invalidate_enrollments(project)
      debug_log("Rebuilding enrollments for #{project.ProjectName} << #{project.organization&.OrganizationName || 'unknown'} in #{project.data_source.short_name}")
      project_source.transaction do
        project.enrollments.invalidate_processing!
      end
      debug_log("done invalidating enrollments for #{project.ProjectName}")
    end

    # Just check the last two years for discrepancies to speed checking
    private def literally_homeless_status_correct?(project)
      if HudUtility2024.chronic_project_types.include?(project.project_type)
        # ES, SO, SH
        any_non_literally_homeless_history = service_history_service_source.
          where(date: 2.years.ago..Date.current).
          joins(service_history_enrollment: :project).
          merge(project_source.where(id: project.id)).
          where.not(literally_homeless: true).exists?
        !any_non_literally_homeless_history
      else
        # PH, TH, and all others
        any_literally_homeless_history = service_history_service_source.
          where(date: 2.years.ago..Date.current).
          joins(service_history_enrollment: :project).
          merge(project_source.where(id: project.id)).
          where(literally_homeless: true).exists?
        !any_literally_homeless_history
      end
    end

    # if the incoming project type is homeless, return true if there are no homeless service history
    # if the incoming project type is non-homeless, return true if there are any that are homeless
    # same for literally_homeless
    def homeless_mismatch?(project)
      !(homeless_status_correct?(project) && literally_homeless_status_correct?(project))
    end

    # If the project only has one CoC Code, set all EnrollmentCoC to match
    # If the project has more than one, clear out any EnrollmentCoC where isn't covered
    def fix_client_locations(project)
      return if skip_location_cleanup

      # debug_log("Setting client locations for #{project.ProjectName}")
      coc_codes = project.project_cocs.map(&:effective_coc_code).uniq.
        # Ensure the CoC codes are valid
        select { |code| HudUtility2024.valid_coc?(code) }
      # Don't do anything if we don't know what CoC the project operates in
      return unless coc_codes.present?

      project.enrollments.where.not(EnrollmentCoC: coc_codes).update_all(EnrollmentCoC: coc_codes.first, source_hash: nil) if coc_codes.count == 1

      project.enrollments.where.not(EnrollmentCoC: coc_codes).update_all(EnrollmentCoC: nil, source_hash: nil)
    end

    # If a project has user provided HMIS Participation records, than we don't need the 2022 -> 2024 migration generated
    # ones, so remove them
    def remove_unneeded_hmis_participations(project)
      hmis_p_t = GrdaWarehouse::Hud::HmisParticipation.arel_table
      return unless project.hmis_participations.where(hmis_p_t[:HMISParticipationID].does_not_match('GR-%', nil, true)).exists?

      project.hmis_participations.where(hmis_p_t[:HMISParticipationID].matches('GR-%', nil, true)).destroy_all
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end

    def service_history_enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def service_history_service_source
      GrdaWarehouse::ServiceHistoryService
    end

    def debug_log message
      @notifier&.ping(message)
    end
  end
end
