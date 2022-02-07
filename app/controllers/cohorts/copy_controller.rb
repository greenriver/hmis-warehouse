###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Cohorts
  class CopyController < ApplicationController
    include CohortAuthorization
    include CohortClients

    before_action :load_cohort
    before_action :load_new, only: [:new]

    def new
    end

    def create
      copy_params = params[:copy] || {}
      if copy_params[:cohort_id].present? && copy_params[:columns].present?
        @copier = GrdaWarehouse::CohortCopier.new(@cohort, cohort_scope, copy_params)
        if @copier.copy!
          redirect_to cohort_path(@cohort)
        else
          render :new
        end
      else
        load_new
        flash[:error] = 'All fields are required.'
        load_new
        render :new
      end
    end

    private

    def load_new
      @cohorts_to_copy_from = cohort_scope.
        where.not(id: @cohort.id).
        pluck(:name, :id)
      @ordered_columns = @cohort.column_state.
        select(&:editable?).
        map { |c| [c.title, c.column] }
    end

    def load_cohort
      @cohort = cohort_scope.find(params[:cohort_id].to_i)
    end
  end
end
