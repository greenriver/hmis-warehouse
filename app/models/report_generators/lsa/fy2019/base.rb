###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportGenerators::Lsa::Fy2019
  class Base
  include ArelHelper
    attr_accessor :report

    def initialize destroy_rds: true, hmis_export_id: nil, options: {}
      @destroy_rds = destroy_rds
      @hmis_export_id = hmis_export_id
      @user = User.find(options[:user_id].to_i) if options[:user_id].present?
      @test = options[:test].present?
    end

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
      if test?
        @coc_code = 'XX-500'
      else
        @coc_code = @report.options['coc_code']
      end
      if @report.options['project_id'].delete_if(&:blank?).any?
        @project_ids = @report.options['project_id'].delete_if(&:blank?).map(&:to_i)
        # Limit to only those projects the user who queued the report can see
        @project_ids = @project_ids & GrdaWarehouse::Hud::Project.viewable_by(@report.user).pluck(:id)
        @lsa_scope = 2
      else
        # Confirmed with HUD only project types 1, 2, 3, 8, 9, 10, 13 need to be included in hmis_ tables.
        @project_ids = system_wide_project_ids
        @lsa_scope = 1
      end
    end

    def system_wide_project_ids
      @system_wide_project_ids ||= GrdaWarehouse::Hud::Project.viewable_by(@user).in_coc(coc_code: @coc_code).
        with_hud_project_type([1, 2, 3, 8, 9, 10, 13]).
        pluck(:id).sort
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

      # Debugging
      # @report = ReportResult.find(902)

      return unless @report.present?
      Rails.logger.info "Starting report #{@report.report.name}"
      @report.update(percent_complete: 0.01)
    end

    def finish_report
      @report.update(
        percent_complete: 100,
        completed_at: Time.now
      )
    end

    def household_types
      @household_types ||= {
        nil: 'All',
        1 => 'AO',
        2 => 'AC',
        3 => 'CO',
      }
    end

    def test?
      @test
    end

    def destroy_rds?
      @destroy_rds
    end
  end
end