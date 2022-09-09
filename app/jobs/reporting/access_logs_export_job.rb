###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting
  class AccessLogsExportJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    def max_attempts
      1
    end

    def perform(filter_params:, cas_user_id:, current_user_id:, filter_user_id:, file_id:)
      # filter is weird, it needs a real user to get started,
      # but we'll need to replace it to get the filtering to work correctly
      @filter = ::Filters::FilterBase.new(user_id: current_user_id)
      @filter.update(filter_params)
      @filter.user_id = filter_user_id

      @report = ::AccessLogs::Report.new(filter: @filter)
      @report.cas_user_id = cas_user_id
      export = ::AccessLogs::Export.where(id: file_id, user_id: current_user_id).first_or_create
      export.update(
        file_data: @report.as_excel.to_stream.read,
        version: 1,
        status: :completed,
        mime_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      )
    end
  end
end
