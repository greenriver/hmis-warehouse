###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class DocumentExportsControllerBase < ApplicationController
  def create
    @export = find_or_create
    if @export.authorized?
      if @export.new_record? || @export.regenerate?
        @export.status = document_export_class::PENDING_STATUS
        @export.save!
        export_job_class.perform_later(export_id: @export.id)
      end
      render json: serialize_export(@export)
    else
      not_authorized!
    end
  end

  def show
    export = export_scope.diet_select.find(params[:id])
    # poll for status, don't bother with auth check
    render json: serialize_export(export)
  end

  def download
    export = export_scope.find(params[:id])
    if export.authorized?
      raise ActiveRecord::RecordNotFound unless export.completed?

      send_data(
        export.file_data,
        filename: export.filename,
        type: export.mime_type,
        disposition: :attachment,
      )
    else
      not_authorized!
    end
  end

  protected def find_or_create
    found = export_scope.
      diet_select.
      completed.
      recent.
      where(export_params).
      first
    found || export_scope.build(export_params)
  end

  protected def serialize_export(export)
    {
      pollUrl: generate_document_export_path(export.id),
      status: export.status,
      downloadUrl: export.completed? ? generate_download_document_export_path(export.id) : nil,
    }
  end

  protected def export_params
    type = params.require(:type).presence_in(valid_document_export_classes)
    raise ActionController::BadRequest, "bad type #{params[:type]}" unless type

    {
      type: type,
      query_string: params[:query_string],
    }
  end

  # NOTE: you must add any new exporters here
  protected def valid_document_export_classes
    [
      'GrdaWarehouse::DocumentExports::ClientPerformanceExport',
      'GrdaWarehouse::DocumentExports::HouseholdPerformanceExport',
      'GrdaWarehouse::DocumentExports::ProjectTypePerformanceExport',
      'CoreDemographicsReport::DocumentExports::CoreDemographicsExport',
      'CoreDemographicsReport::DocumentExports::CoreDemographicsExcelExport',
      'CoreDemographicsReport::DemographicSummary::DocumentExports::DemographicSummaryExport',
      'CoreDemographicsReport::DemographicSummary::DocumentExports::DemographicSummaryExcelExport',
      'ProjectPassFail::DocumentExports::ProjectPassFailExport',
      'GrdaWarehouse::DocumentExports::BasePerformanceExport',
      'Health::DocumentExports::HousingStatusChangesExport',
      'Health::DocumentExports::AgencyPerformanceExport',
      'ProjectScorecard::DocumentExports::ScorecardExport',
      'BostonProjectScorecard::DocumentExports::ScorecardExport',
      'HudApr::DocumentExports::HudAprExport',
      'HudApr::DocumentExports::HudCaperExport',
      'HudApr::DocumentExports::HudCeAprExport',
      'HudApr::DocumentExports::HudDqExport',
      'HudPathReport::DocumentExports::HudPathReportExport',
      'HudSpmReport::DocumentExports::HudSpmReportExport',
      'HudDataQualityReport::DocumentExports::HudDataQualityReportExport',
      'GrdaWarehouse::DocumentExports::BedUtilizationExport',
      'PerformanceMeasurement::DocumentExports::ReportExport',
      'HomelessSummaryReport::DocumentExports::ReportExport',
      'GrdaWarehouse::WarehouseReports::DocumentExports::ActiveClientReportExport',
      'BostonReports::DocumentExports::StreetToHomePdfExport',
      'BostonReports::DocumentExports::CommunityOfOriginPdfExport',
      'HmisDataQualityTool::DocumentExports::ReportExport',
      'HmisDataQualityTool::DocumentExports::ReportChartPdfExport',
      'HmisDataQualityTool::DocumentExports::ReportExcelExport',
      'HmisDataQualityTool::DocumentExports::ReportByClientExcelExport',
      'SystemPathways::DocumentExports::ReportExport',
      'SystemPathways::DocumentExports::ReportExcelExport',
      'HealthPctp::DocumentExports::HealthPctpPdfExport',
      'HealthPctp::DocumentExports::HealthPctpSignaturePdfExport',
      'HealthComprehensiveAssessment::DocumentExports::HealthCaPdfExport',
      'StartDateDq::DocumentExports::StartDateDqExcelExport',
      'ClientDocumentsReport::DocumentExports::ReportExcelExport',
      'InactiveClientReport::DocumentExports::ReportExcelExport',
      'ZipCodeReport::DocumentExports::ReportExcelExport',
      'GrdaWarehouse::Cohorts::DocumentExports::CohortExcelExport',
      'UserDirectoryReport::DocumentExports::CasUserDirectoryExcelExport',
      'UserDirectoryReport::DocumentExports::WarehouseUserDirectoryExcelExport',
      'TxClientReports::AttachmentThreeReportExports::AttachmentThreeReportExcelExport',
      'HopwaCaper::DocumentExports::HopwaCaperExport',
    ]
  end
end
