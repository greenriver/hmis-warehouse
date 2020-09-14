###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr
  class BaseController < ApplicationController
    def set_generator(param_name:) # rubocop:disable Naming/AccessorMethodName
      @generator_id = params[param_name].to_i
      @generator = generators[@generator_id]
    end

    def set_report(param_name:) # rubocop:disable Naming/AccessorMethodName
      report_id = params[param_name].to_i
      # APR 0 is the most recent report for the current user
      if report_id.zero?
        @report = @generator.find_report(current_user)
      else
        @report = report_source.find(report_id)
      end
    end

    def filter_options
      filter = params.require(:filter).
        permit(
          :start_date,
          :end_date,
          :coc_code,
          project_ids: [],
        )
      filter[:user_id] = current_user.id
      filter[:project_ids] = filter[:project_ids].reject(&:blank?).map(&:to_i)
      filter
    end

    def generators
      [
        HudApr::Generators::Apr::Fy2020::Generator,
      ]
    end

    def report_source
      HudReports::ReportInstance
    end
  end
end
