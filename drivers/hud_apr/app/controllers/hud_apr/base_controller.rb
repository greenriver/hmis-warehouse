###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr
  class BaseController < ::HudReports::BaseController
    before_action :filter

    def filter_params
      return {} unless params[:filter]

      filter_p = params.require(:filter).permit(@filter.known_params)
      filter_p[:user_id] = current_user.id
      filter_p[:enforce_one_year_range] = false
      # filter[:project_ids] = filter[:project_ids].reject(&:blank?).map(&:to_i)
      # filter[:project_group_ids] = filter[:project_group_ids].reject(&:blank?).map(&:to_i)
      filter_p
    end

    private def filter
      year = if Date.current.month >= 10
        Date.current.year
      else
        Date.current.year - 1
      end
      # Some sane defaults, using the previous report if available
      @filter = filter_class.new(user_id: current_user.id, enforce_one_year_range: false)
      if filter_params.blank?
        prior_report = generator.find_report(current_user)
        options = prior_report&.options
        site_coc_codes = GrdaWarehouse::Config.get(:site_coc_codes).presence&.split(/,\s*/)
        if options.present?
          @filter.start = options['start'].presence || Date.new(year - 1, 10, 1)
          @filter.end = options['end'].presence || Date.new(year, 9, 30)
          @filter.coc_codes = options['coc_codes'].presence || site_coc_codes
          @filter.update(options.with_indifferent_access)
        else
          @filter.start = Date.new(year - 1, 10, 1)
          @filter.end = Date.new(year, 9, 30)
          @filter.coc_codes = site_coc_codes
        end
      end
      # Override with params if set
      @filter.update(filter_params) if filter_params.present?
    end

    private def filter_class
      generator.filter_class
    end
  end
end
