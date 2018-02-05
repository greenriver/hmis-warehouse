module Cohorts
  class ColumnsController < ApplicationController
    include PjaxModalController
    before_action :require_can_manage_cohorts!
    before_action :set_cohort

    def edit
      @column_state = @cohort.column_state&.presence || cohort_source.available_columns
    end

    def update
      columns = cohort_source.available_columns.deep_dup
      if params.include? :order
        columns = columns.sort_by{|x| params[:order].index x.column.to_s}
      end
      columns.each do |column|
        column.visible = if cohort_params[column.column].blank? || cohort_params[column.column].to_s == '0' then false else true end
      end
      @cohort.update(column_state: columns)
      respond_with(@cohort, location: cohort_path(@cohort))
    end

    def cohort_params
      params.require(:column_state).permit(
        *cohort_source.available_columns.map(&:column)
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
