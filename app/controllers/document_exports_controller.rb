###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class DocumentExportsController < ApplicationController
  def create
    @export = find_or_create
    if @export.authorized?
      if @export.new_record?
        @export.status = GrdaWarehouse::DocumentExport::PENDING_STATUS
        @export.save!
        DocumentExportJob.perform_later(export_id: @export.id)
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
    found = export_scope
      .diet_select
      .completed
      .recent
      .where(export_params)
      .first
    found ? found : export_scope.build(export_params)
  end

  protected def serialize_export(export)
    {
      pollUrl: document_export_path(export.id),
      status: export.status,
      downloadUrl: export.completed? ? download_document_export_path(export.id) : nil,
    }
  end

  protected def export_scope
    current_user.document_exports
  end

  protected def export_params
    valid_types = GrdaWarehouse::DocumentExport.subclasses.map(&:name)
    type = params.require(:type).presence_in(valid_types)
    raise ActionController::BadRequest, "bad type #{params[:type]}" unless type

    {
      type: type,
      query_string: params[:query_string],
    }
  end
end
