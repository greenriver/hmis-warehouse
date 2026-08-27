###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ImportsController < ApplicationController
  before_action :require_can_view_imports!
  before_action :set_import, only: [:show, :edit, :update, :destroy, :download]

  # GET /imports
  def index
    @imports = import_scope.select(:id, :data_source_id, :completed_at, :created_at, :updated_at, :upload_id).
      order(created_at: :desc)
    @pagy, @imports = pagy(@imports)
  end

  def show
  end

  def download
    return unless (@upload = @import.upload)

    zip = @upload.hmis_zip
    filename = zip.filename&.to_s.presence || 'import'
    send_data(zip.download, type: zip.content_type, filename: filename) if zip.present?
  end

  def download_upload
    @upload = GrdaWarehouse::Upload.viewable_by(current_user).find(params[:id].to_i)
    zip = @upload.hmis_zip
    filename = zip.filename&.to_s.presence || 'import'
    send_data(zip.download, type: zip.content_type, filename: filename) if zip.present?
  end

  private def import_scope
    GrdaWarehouse::ImportLog.viewable_by(current_user)
  end

  # Use callbacks to share common setup or constraints between actions.
  private def set_import
    sti_col = import_scope.inheritance_column
    @import = import_scope.find(params.require(:id))
  rescue ActiveRecord::SubclassNotFound
    # Importers are optional driver components now
    # so we fallback to loading as the generic log interface
    import_scope.inheritance_column = :_disabled
    @import = import_scope.find(params.require(:id))
  ensure
    import_scope.inheritance_column = sti_col
  end
end
