###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Cohorts
  class ColumnsController < ApplicationController
    include AjaxModalRails::Controller
    before_action :require_can_edit_some_cohorts!
    before_action :set_cohort

    def edit
      @modal_size = :lg
      @column_state = @cohort.column_state&.presence || cohort_source.default_visible_columns
    end

    def update
      columns = cohort_source.available_columns.deep_dup
      if params.include? :order
        order = params[:order].split(',')
        columns = columns.sort_by { |col| order.index(col.column.to_s) || 500 }
      end
      columns.each do |column|
        visibility_state = cohort_params[:visible][column.column]
        column.visible = false
        column.visible = true if visibility_state.present? || visibility_state.to_s == '1'

        editability_state = begin
                              cohort_params[:editable][column.column]
                            rescue StandardError
                              nil
                            end
        column.editable = false
        column.editable = true if editability_state.present? || editability_state.to_s == '1'
      end
      @cohort.update(column_state: columns)

      respond_with(@cohort, location: cohort_path(@cohort))
    end

    def cohort_params
      params.require(:column_state).permit(
        visible: cohort_source.available_columns.map(&:column),
        editable: cohort_source.available_columns.map(&:column),
      )
    end

    def set_cohort
      @cohort = cohort_source.find(params[:cohort_id].to_i)
    end

    def cohort_source
      GrdaWarehouse::Cohort
    end

    def flash_interpolation_options
      { resource_name: @cohort.name }
    end
  end
end
