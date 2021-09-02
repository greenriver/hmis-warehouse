###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class DocumentExportsControllerBase < ApplicationController
  def create
    @export = find_or_create
    if @export.authorized?
      if @export.new_record?
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
      'ProjectPassFail::DocumentExports::ProjectPassFailExport',
      'GrdaWarehouse::DocumentExports::BasePerformanceExport',
      'Health::DocumentExports::HousingStatusChangesExport',
      'Health::DocumentExports::AgencyPerformanceExport',
      'ProjectScorecard::DocumentExports::ScorecardExport',
      'HudApr::DocumentExports::HudAprExport',
    ]
  end
end
