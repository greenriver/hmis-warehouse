###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class FiltersController < ApplicationController
  include AjaxModalRails::Controller
  def show
    @filter = filter.update(filter_params)
    selected_keys
  end

  private def filter_params
    params.require(:filter).permit(filter.known_params)
  end
  helper_method :filter_params

  private def selected_keys
    @selected_keys ||= params[:selected_keys].presence&.map(&:to_sym) || []
  end

  private def filter
    @filter ||= ::Filters::FilterBase.new(user_id: current_user.id)
  end
end
