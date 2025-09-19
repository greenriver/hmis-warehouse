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

      log_client_file_access(file)
      redirect_to object_url(file), allow_other_host: true
    end

    protected

    def redacted?(file)
      # This file is not confidential, therefore not redacted
      return false unless file.confidential
      # This user uploaded this file and the user still has access to files they control, therefore not redacted
      return false if file.user_id == current_hmis_user.id && current_hmis_user.can_manage_own_client_files_for?(file)

      # Can user can see any confidential files in this data source? Redact if not
      !current_hmis_user.can_view_any_confidential_client_files_for?(file)
    end

    # returns the direct url to the active storage file with a short expiration
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
      params[:disposition].presence_in(dispositions) || dispositions.first
    end

    def object_file_name(file)
      result = file.name.presence || "file-#{file.id}"
      ActiveStorage::Filename.new(result).sanitized
    end

    def load_authorized_client_file
      client = Hmis::Hud::Client.viewable_by(current_hmis_user).find(params[:client_id])
      Hmis::File.where(client: client).
        viewable_by(current_hmis_user, client_ids: [client.id]).find(params[:id])
    end

    def log_client_file_access(file)
      # Link this event to the client for downstream processing (join-table population)
      resolved_fields = {
        "Client/#{file.client_id}" => ['files'],
        "File/#{file.id}" => ['url'],
      }

      row = {
        user_id: true_hmis_user.id,
        data_source_id: current_hmis_user.hmis_data_source_id,
        ip_address: request.remote_ip&.to_s,
        session_hash: session.id&.to_s,
        request_id: request.uuid,
        variables: { 'fileId' => file.id, 'clientId' => file.client_id },
        referer: request.referer,
        operation_name: 'ClientFileRedirect',
        header_page_path: request.headers['X-Hmis-Path'].presence,
        header_client_id: request.headers['X-Hmis-Client-Id'].presence&.to_i,
        header_enrollment_id: request.headers['X-Hmis-Enrollment-Id'].presence&.to_i,
        header_project_id: request.headers['X-Hmis-Project-Id'].presence&.to_i,
        created_at: Time.current,
        resolved_fields: resolved_fields,
        resolved_at: Time.current,
      }
      Hmis::ActivityLog.insert_all!([row])
    end
  end
end
