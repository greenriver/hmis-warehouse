module ReportGenerators::SystemPerformance::Fy2016
  class Base
  include ArelHelper

    def add_filters scope:
      if @report.options['project_id'].delete_if(&:blank?).any?
        project_ids = @report.options['project_id'].delete_if(&:blank?).map(&:to_i)
        scope = scope.joins(:project).where(project: { id: project_ids})
      end
      if @report.options['data_source_id'].present?
        scope = scope.where(data_source_id: @report.options['data_source_id'].to_i)
      end
      if @report.options['coc_code'].present?
        scope = scope.coc_funded_in(coc_code: @report.options['coc_code'])
      end

      return scope
    end

    def act_as_coc_overlay
      pt = GrdaWarehouse::Hud::ProjectCoC.arel_table
      nf( 'COALESCE', [ pt[:hud_coc_code], pt[:CoCCode] ] ).as('CoCCode').to_sql
    end

    def act_as_project_overlay
      pt = GrdaWarehouse::Hud::Project.arel_table
      st = GrdaWarehouse::ServiceHistory.arel_table
      nf( 'COALESCE', [ pt[:act_as_project_type], st[:project_type] ] ).as('project_type').to_sql
    end

    def replace_project_type_with_overlay(headers)
      headers.map do |v| 
        if v == :project_type 
          act_as_project_overlay 
        else
          v 
        end
      end
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
        results: @answers,
        support: @support,
        completed_at: Time.now
      )
    end
  end
end