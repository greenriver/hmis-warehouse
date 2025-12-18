###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class DelayedJobsController < ApplicationController
    # Stand in permission
    before_action :require_can_add_administrative_event!
    before_action :set_job, only: [:update, :destroy, :cancel]

    def index
      @jobs = job_scope.order(priority: :asc, run_at: :asc, queue: :asc)
      @users = User.active.map { |u| [u.id, u.name_with_email] }.to_h
    end

    def update
      @job.update(locked_by: nil, locked_at: nil, failed_at: nil, last_error: nil)
      flash[:notice] = 'Delayed Job re-queued'
      redirect_to admin_delayed_jobs_path
    end

    def cancel
      @job.update(cancellation_requested_at: Time.current)
      flash[:notice] = 'Job cancellation requested'
      redirect_to admin_delayed_jobs_path
    end

    def destroy
      @job.destroy
      flash[:notice] = 'Delayed Job deleted'
      redirect_to admin_delayed_jobs_path
    end

    private def job_scope
      Delayed::Job
    end

    private def set_job
      @job = job_scope.find(params[:id].to_i)
    end
  end
end
