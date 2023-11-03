###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Concerns::HmisActivityLogger
  extend ActiveSupport::Concern

  def log_gql_activity(gql_param)
    attrs = {
      user_id: current_hmis_user.id, # FIXME: true_user if masquerading
      data_source_id: current_hmis_user.hmis_data_source_id,
      ip_address: request.remote_ip,
      referer: request.referer,
      session_hash: session.id,
      operation_name: gql_param[:operationName],
      variables: gql_param[:variables],
      # these are pulled from headers so they are not necessarily safe, could be tampered with
      path: request.headers['X-Hmis-Path'], # is this safe? unsafe header
      client_id: request.headers['X-Hmis-Client-Id']&.to_i, # FIXME becomes 0 if non numeric. unsafe header
      enrollment_id: request.headers['X-Hmis-Enrollment-Id']&.to_i,
      project_id: request.headers['X-Hmis-Project-Id']&.to_i,

    }
    Rails.logger.info(">>> attrs #{attrs}")
    Hmis::ActivityLog.create!(attrs)
  end
end
