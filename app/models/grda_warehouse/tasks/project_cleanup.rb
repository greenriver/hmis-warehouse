###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Tasks
  class ProjectCleanup
    include ArelHelper
    include NotifierConfig
    attr_accessor :logger, :send_notifications, :notifier_config

    def initialize(bogus_notifier=false, debug: false)
      setup_notifier('Project Cleaner')
      self.logger = Rails.logger
      @debug = debug
    end

    def run!
      debug_log("Cleaning projects")
      @projects = load_projects()

      @projects.each do |project|
        if should_update_type?(project)
          debug_log("Updating type for #{project.ProjectName} << #{project.organization&.OrganizationName || 'unknown'} in #{project.data_source.short_name}...#{project.ProjectType} #{project.act_as_project_type} #{sh_project_types(project).inspect}")
          project_type = project.compute_project_type()
          # Force a rebuild of all related enrollments
          project_source.transaction do
            project.enrollments.update_all(processed_as: nil)
            project.update(computed_project_type: project_type)
          end
          # wait for re-processing
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.unprocessed.
            joins(:project, :destination_client).
            pluck_in_batches(:id, batch_size: 250) do |batch|
              Delayed::Job.enqueue(::ServiceHistory::RebuildEnrollmentsByBatchJob.new(enrollment_ids: batch), queue: :low_priority)
            end
          GrdaWarehouse::Tasks::ServiceHistory::Update.wait_for_processing
          debug_log("done")
        elsif homeless_mismatch?(project) # if should_update_type? returned true, these have been fixed
          debug_log("Rebuilding enrollments for #{project.ProjectName} << #{project.organization&.OrganizationName || 'unknown'} in #{project.data_source.short_name}")
          project_source.transaction do
            project.enrollments.update_all(processed_as: nil)
          end
          # wait for re-processing
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.unprocessed.
            joins(:project, :destination_client).
            pluck_in_batches(:id, batch_size: 250) do |batch|
              Delayed::Job.enqueue(::ServiceHistory::RebuildEnrollmentsByBatchJob.new(enrollment_ids: batch), queue: :low_priority)
            end
          GrdaWarehouse::Tasks::ServiceHistory::Update.wait_for_processing
          debug_log("done")
        end

        if should_update_name?(project)
          debug_log("Updating name for #{project.ProjectName}")
          project_source.transaction do
            # Update any service records with this project
            service_history_enrollment_source.
              where(project_id: project.ProjectID, data_source_id: project.data_source_id).
              where.not(project_name: project.ProjectName).
              update_all(project_name: project.ProjectName)
          end
          debug_log("done")
        end
      end
    end

    def load_projects
      project_source.all
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

    # if the incoming project type is homeless, return true if there are no homeless service history
    # if the incoming project type is non-homeless, return true if there are any that are homeless
    # same for literally_homeless
    def homeless_mismatch? project
      homeless = GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES.include?(project.computed_project_type)
      literally_homeless = GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES.include?(project.computed_project_type)
      homeless_mismatch = false
      literally_homeless_mismatch = false
      if homeless
        no_homeless_history = service_history_service_source.joins(service_history_enrollment: :project).
          merge(project_source.where(id: project.id)).
          where.not(homeless: true).exists?
        homeless_mismatch = !no_homeless_history
      else
        homeless_mismatch = service_history_service_source.joins(service_history_enrollment: :project).
          merge(project_source.where(id: project.id)).
          where(homeless: true).exists?
      end

      if literally_homeless
        no_literally_homeless_history = service_history_service_source.joins(service_history_enrollment: :project).
          merge(project_source.where(id: project.id)).
          where.not(literally_homeless: true).exists?
        literally_homeless_mismatch = !no_literally_homeless_history
      else
        literally_homeless_mismatch = service_history_service_source.joins(service_history_enrollment: :project).
          merge(project_source.where(id: project.id)).
          where(literally_homeless: true).exists?
      end
      homeless_mismatch || literally_homeless_mismatch
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
      @notifier.ping message if @notifier
      logger.info message if @debug
    end
  end
end
