module ReportGenerators::Lsa::Fy2018
  class Base
  include ArelHelper

    def setup_filters
      # convert various inputs to project ids for the HUD HMIS export
      project_group_ids = @report.options['project_group_ids'].delete_if(&:blank?).map(&:to_i)
      if project_group_ids.any?
        project_group_project_ids = GrdaWarehouse::ProjectGroup.where(id: project_group_ids).map(&:project_ids).flatten.compact
        @report.options['project_id'] |= project_group_project_ids
      end
      data_source_id = @report.options['data_source_id'].presence&.to_i
      if data_source_id.present?
        @report.options['project_id'] |= GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id).pluck(:id)
      end
      coc_codes = @report.options['coc_code']
      if coc_codes.present?
        @report.options['project_id'] |= GrdaWarehouse::Hud::Project.joins(:project_cocs).
          merge(GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_codes)).distinct.pluck(:id)
      end
      if @report.options['project_id'].delete_if(&:blank?).any?
        @project_ids = @report.options['project_id'].delete_if(&:blank?).map(&:to_i)
      else
        @project_ids = GrdaWarehouse::Hud::Project.pluck(:id)
      end
    end

    def set_report_start_and_end
      @report_start ||= @report.options['report_start'].to_date
      @report_end ||= @report.options['report_end'].to_date
    end

    def update_report_progress percent:
      @report.update(
        percent_complete: percent,
      )
    end

    def start_report(report)
      # Find the first queued report
      @report = ReportResult.where(
        report: report,
        percent_complete: 0
      ).first
      return unless @report.present?
      Rails.logger.info "Starting report #{@report.report.name}"
      @report.update(percent_complete: 0.01)
    end

    def finish_report
      @report.update(
        percent_complete: 100,
        results: @answers, # This will be a zip file
        completed_at: Time.now
      )
    end
  end
end