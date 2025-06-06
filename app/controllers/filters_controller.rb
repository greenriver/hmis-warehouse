###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class FiltersController < ApplicationController
  include AjaxModalRails::Controller
  def show
    @filter = filter
    # The Project Type Codes can be set by default, we don't want to show them if they were not selected by the user
    @filter.project_type_codes = []
    filter.update(filter_params)
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
