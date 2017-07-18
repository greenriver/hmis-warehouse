module GrdaWarehouse::Tasks
  class CalculateProjectTypes
    include ArelHelper
    attr_accessor :logger, :send_notifications
    def initialize(bogus_notifier=false, debug: false)
      exception_notifier_config = Rails.application.config_for(:exception_notifier)['slack']
      @send_notifications = (Rails.env.development? || Rails.env.production?) && exception_notifier_config.present?
      if @send_notifications
        slack_url = exception_notifier_config['webhook_url']
        channel = exception_notifier_config['channel']
        @notifier = Slack::Notifier.new slack_url, channel: channel, username: 'ProjectTypeCalculator'
      end
      self.logger = Rails.logger
      @debug = debug
    end
    def run!
      debug_log("Updating project types")
      @projects = load_projects()
      
      @projects.each do |project|
        if should_update?(project)
          debug_log("Updating #{project.ProjectName}...")
          project_type = project.compute_project_type()
          project_source.transaction do
            # Update any service records with this project
            service_history_source.
              where(project_id: project.ProjectID, data_source_id: project.data_source_id).
              update_all(computed_project_type: project_type)
            # Update the project after so that if it fails we trigger a re-update of both
            project.update(computed_project_type: project_type)
          end
          debug_log("done")
        end
      end
    end

    def load_projects
      project_source.all
    end

    def should_update? project
      (project.act_as_project_type.present? && project.act_as_project_type != project.computed_project_type) || (project.act_as_project_type.blank? && project.ProjectType != project.computed_project_type)
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end

    def debug_log message
      @notifier.ping message if @notifier
      logger.info message if @debug
    end
  end
end