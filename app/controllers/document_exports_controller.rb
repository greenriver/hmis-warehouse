###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class DocumentExportsController < ApplicationController
  def create
    @export = export_scope.build(
      type: params.require(:type),
      params: params.require(:params),
      status: DocumentExport::NEW_STATUS,
    )
    if @export.authorized?
      @export.save!
      DocumentExportJob.perform_later(@export.id)
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
          url: @export.file&.url,
        }
        render json: payload
      end
      format.html
    end
  end

  private def export_scope
    current_user.document_exports
  end
end
