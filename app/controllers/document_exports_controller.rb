###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class DocumentExportsController < ApplicationController

  def create
    @export = export_scope.build(export_params)
    if @export.authorized?
      @export.save!
      DocumentExportJob.perform_later(export_id: @export.id)
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
      if export.completed?
        send_data(
          export.file_data,
          filename: export.filename,
          type: export.mime_type,
          disposition: :attachment
        )
      else
        raise ActiveRecord::RecordNotFound
      end
    else
      not_authorized!
    end
  end

  protected def serialize_export(export)
    {
      pollUrl: document_export_path(export.id),
      status: export.status,
      url: export.completed? ? download_document_export_path(export.id) : nil
    }
  end

  protected def export_scope
    current_user.document_exports
  end

  protected def export_params
    valid_types = DocumentExport.subclasses.map(&:name)
    type = params.require(:type).presence_in(valid_types)
    raise ActionController::BadRequest, "bad type #{params[:type]}" unless type

    {
      type: type,
      query_string: params[:query_string],
      status: DocumentExport::PENDING_STATUS,
    }
  end
end
