###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks
  class ProjectCleanup
    include ArelHelper
    include NotifierConfig

    def initialize(
      _bogus_notifier = false,
      project_ids: GrdaWarehouse::Hud::Project.select(:id),
      debug: false
    )
      setup_notifier('Project Cleaner')
      @project_ids = project_ids
      @debug = debug
    end

    def run!
      @start_time = Time.current
      debug_log('Cleaning projects')
      @projects = load_projects

      @projects.each do |project|
        next unless project.enrollments.exists?

        if should_update_type?(project)
          fix_project_type(project)
        elsif homeless_mismatch?(project) # if should_update_type? returned true, these have been fixed
          invalidate_enrollments(project)
        end

        fix_name(project)
        fix_client_locations(project)
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
      project_override_changed = (project.act_as_project_type.present? && project.act_as_project_type != project.computed_project_type) || (project.act_as_project_type.blank? && project.ProjectType != project.computed_project_type)

      sh_project_types_for_check = sh_project_types(project)
      project_types_match_sh_types = true
      if sh_project_types_for_check.count == 1
        (project_type, computed_project_type) = sh_project_types_for_check.first
        project_types_match_sh_types = project.ProjectType == project_type && project.computed_project_type == computed_project_type
      end
      project_type_changed_in_source = sh_project_types_for_check.count > 1
      project_type_changed_in_source || project_override_changed || ! project_types_match_sh_types
    end

    def fix_project_type(project)
      blank_initial_computed_project_type = project.computed_project_type.blank?
      debug_log("Updating type for #{project.ProjectName} << #{project.organization&.OrganizationName || 'unknown'} in #{project.data_source.short_name}... current ProjectType: #{project.ProjectType} acts_as: #{project.act_as_project_type} project types in Service History:  #{sh_project_types(project).inspect}") unless blank_initial_computed_project_type
      project_type = project.compute_project_type
      # Force a rebuild of all related enrollments
      project_source.transaction do
        project.enrollments.invalidate_processing!
        project.update(computed_project_type: project_type)
        # Fix the SHE with record_type "first"
        service_history_enrollment_source.where(
          project_id: project.ProjectID,
          data_source_id: project.data_source_id,
        ).update_all(computed_project_type: project_type, project_type: project_type)
      end
      debug_log("done invalidating enrollments for #{project.ProjectName}") unless blank_initial_computed_project_type
    end

    def sh_project_types project
      service_history_enrollment_source.
        where(data_source_id: project.data_source_id, project_id: project.ProjectID).
        distinct.
        pluck(:project_type, :computed_project_type)
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
      if HudUtility2024.homeless_project_types.include?(project.computed_project_type)
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
      if HudUtility2024.chronic_project_types.include?(project.computed_project_type)
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
      # debug_log("Setting client locations for #{project.ProjectName}")
      coc_codes = project.project_cocs.map(&:effective_coc_code).uniq
      project.enrollments.where.not(EnrollmentCoC: coc_codes).update_all(EnrollmentCoC: coc_codes.first) if coc_codes.count == 1

      project.enrollments.where.not(EnrollmentCoC: coc_codes).update_all(EnrollmentCoC: nil)
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
