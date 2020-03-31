###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class PerformanceDashboards::BaseController < ApplicationController
  def set_filter
    @start_date = params.dig(:filters, :start_date)&.to_date || Date.current
    @end_date = params.dig(:filters, :end_date)&.to_date || @start_date - 1.year
    @coc_codes = params.dig(:filters, :coc_codes)&.select { |code| PerformanceDashboards::Overview.coc_codes.include?(code) } || []
    @household_type = params.dig(:filters, :household_type)&.to_sym
    @hoh_only = params.dig(:filters, :hoh_only) == '1'
    @project_type_codes = params.dig(:filters, :project_types)&.reject { |type| type.blank? } || []
    @project_types = @project_type_codes.map { |type| GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[type.to_sym] }.flatten if @project_type_codes.present?
    @veteran_statuses = params.dig(:filters, :veteran_statuses)&.reject { |status| status.blank? }&.map { |status| status.to_i } || []
    @age_ranges = params.dig(:filters, :age_ranges)&.reject { |range| range.blank? }&.map { |range| range.to_sym } || []
    @genders = params.dig(:filters, :genders)&.reject { |gender| gender.blank? }&.map { |gender| gender.to_i } || []
    races = params.dig(:filters, :races)&.select { |race| HUD.races.keys.include?(race) } || []
    @races = races.map { |race| [race, 1] }.to_h
    @ethnicities = params.dig(:filters, :ethnicities)&.reject { |ethnicity| ethnicity.blank? }&.map { |ethnicity| ethnicity.to_i } || []
  end
end
