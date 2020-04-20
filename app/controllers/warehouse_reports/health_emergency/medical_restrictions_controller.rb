###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::HealthEmergency
  class MedicalRestrictionsController < ApplicationController
    include ArelHelper
    include PjaxModalController
    include WarehouseReportAuthorization
    include WarehouseReportsHealthEmergencyController
    before_action :require_can_see_health_emergency_clinical!

    def index
      @restrictions = restriction_scope.added_within_range(@filter.range).
        joins(client: [:processed_service_history, :service_history_enrollments])
      if @filter.effective_project_ids_from_projects.present?
        @restrictions = @restrictions.merge(
          GrdaWarehouse::ServiceHistoryEnrollment.
            joins(:project).
            service_within_date_range(start_date: @filter.start, end_date: Date.current).
            merge(GrdaWarehouse::Hud::Project.where(id: project_ids)),
        )
      else
        @restrictions = @restrictions.merge(
          GrdaWarehouse::ServiceHistoryEnrollment.
            joins(:project).
            merge(GrdaWarehouse::Hud::Project.where(id: project_ids)),
        )
      end
      @restrictions = @restrictions.distinct
      respond_to do |format|
        format.html do
          @pdf = false
          @html = true
          @restrictions = @restrictions.page(params[:page]).
            per(25)
        end
        format.pdf do
          @restrictions = @restrictions.to_a.sort_by do |a|
            [a.client.LastName, a.client.FirstName]
          end
          @pdf = true
          @html = false
          render_pdf!
        end
      end
    end

    private def render_pdf!
      file_name = "Medical Restrictions #{DateTime.current.to_s(:db)}"
      send_data pdf, filename: "#{file_name}.pdf", type: 'application/pdf'
    end

    def pdf
      grover_options = {
        display_url: root_url,
        displayHeaderFooter: true,
        headerTemplate: '<h2>Header</h2>',
        footerTemplate: '<h6 class="text-center">Footer</h6>',
        timeout: 50_000,
        format: 'Letter',
        emulate_media: 'print',
        margin: {
          top: '.5in',
          bottom: '.5in',
          left: '.4in',
          right: '.4in',
        },
        debug: {
          # headless: false,
          # devtools: true
        },
      }

      html = render_to_string('warehouse_reports/health_emergency/medical_restrictions/index')
      Grover.new(html, grover_options).to_pdf
    end

    private def restriction_scope
      GrdaWarehouse::HealthEmergency::AmaRestriction.active.visible_to(current_user).newest_first
    end

    def report_index
      warehouse_reports_health_emergency_medical_restrictions_path
    end
    helper_method :report_index
  end
end
