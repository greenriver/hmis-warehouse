###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Cohorts
  class CopyController < ApplicationControllerV2
    include CohortAuthorization
    include CohortClients

    NO_COPYABLE_COLUMNS = "You can't edit any columns in this cohort."
    ALL_FIELDS_REQUIRED = 'All fields are required.'

    before_action :load_cohort
    authorize_with { cohort_policy.can_add_clients? }
    before_action :refuse_managed_cohort
    before_action :load_new, only: [:new]

    def new
      flash.now[:error] = NO_COPYABLE_COLUMNS if @ordered_columns.empty?
    end

    def create
      copy_params = params[:copy].respond_to?(:permit) ? params[:copy].permit(:cohort_id, columns: []) : {}
      load_new
      return render_new(NO_COPYABLE_COLUMNS) if @ordered_columns.empty?
      return render_new(ALL_FIELDS_REQUIRED) if copy_params[:cohort_id].blank?
      return render_new('Choose a different cohort to copy from.') if copy_params[:cohort_id].to_i == @cohort.id

      @copier = GrdaWarehouse::CohortCopier.new(@cohort, cohort_scope, copy_params, user: current_user)
      return render_new(ALL_FIELDS_REQUIRED) unless @copier.copyable?

      @copier.copy!
      redirect_to cohort_path(@cohort)
    end

    private

    def render_new(message)
      flash.now[:error] = message
      render :new
    end

    def refuse_managed_cohort
      redirect_to cohort_path(@cohort) if @cohort.system_cohort || @cohort.auto_maintained?
    end

    def load_new
      @cohorts_to_copy_from = cohort_scope.
        where.not(id: @cohort.id).
        pluck(:name, :id)
      @ordered_columns = GrdaWarehouse::CohortCopier.copyable_columns(@cohort, current_user).
        map { |c| [c.title, c.column] }
    end

    def cohort_id
      params[:cohort_id].to_i
    end
  end
end
