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
      render 'show', layout: false
    else
      not_authorized!
    end
  end

  def show
    @export = export_scope.find(params[:id])
    respond_to do |format|
      format.json do
        payload = {
          status: @export.status,
          # this doesn't work in development, would like to get an expiring s3 url here
          url: @export.file&.url,
        }
        render json: payload
      end
      format.html
    end
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
      status: DocumentExport::NEW_STATUS,
    }
  end
end
