
###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  class ClientFilesController < Hmis::BaseController
    before_action :attach_data_source_id

    def show
      file = load_authorized_client_file
      return head(:not_found) if redacted?(file) || !file.client_file.attached?

      redirect_to object_url(file), allow_other_host: true
    end

    protected

    def redacted?(file)
      return false unless file.confidential
      return false if file.user_id == current_user.id && current_user.can_manage_own_client_files_for?(file)

      !current_user.can_view_any_confidential_client_files_for?(file)
    end

    def object_url(file)
      file.client_file.blob.url(
        filename: object_file_name(file),
        expires_in: file_expires_in,
        disposition: file_disposition,
      )
    end

    def file_expires_in
      5.minutes
    end

    def file_disposition
      dispositions = ['inline', 'attachment']
      params[:disposition].presence_in?(dispositions) || dispositions.first
    end

    def object_file_name(file)
      result = file.name.presence || "file-#{file.id}"
      ActiveStorage::Filename.new(result).sanitized
    end

    def load_authorized_client_file
      client = Hmis::Hud::Client.viewable_by(current_hmis_user).find(params[:client_id])
      Hmis::File.viewable_by(current_hmis_user, client_ids: [client.id]).find(params[:id])
    end
  end
end
