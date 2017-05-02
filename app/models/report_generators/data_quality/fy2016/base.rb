module ReportGenerators::DataQuality::Fy2016
  class Base
    include ArelHelper

    def add_filters scope:
      if @report.options['project_id'].present?
        scope = scope.joins(:project).where(project: { id: @report.options['project_id'].to_i})
      end
      if @report.options['data_source_id'].present?
        scope = scope.where(data_source_id: @report.options['data_source_id'].to_i)
      end
      if @report.options['coc_code']
        scope = scope.coc_funded_in(coc_code: @report.options['coc_code'])
      end
      if @report.options['project_type']
        project_types = @report.options['project_type'].compact.map(&:to_i)
        scope = scope.where(project_type: project_types).joins(:project).act_as_project_overlay
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

    def all_client_scope
      client_scope = GrdaWarehouse::ServiceHistory.entry.
        open_between(start_date: @report.options['report_start'],
          end_date: @report.options['report_end']).
        joins(:client)

      add_filters(scope: client_scope)
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

    def add_support headers:, data:
      {
        headers: headers,
        counts: data,
      }
    end

    def update_report_progress percent:
      @report.update(
        percent_complete: percent,
        results: @answers,
        support: @support,
      )
    end
    def all_client_count 
      count ||= @all_clients.size
    end
  end
end