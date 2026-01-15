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
    end

    def update
      @job.with_lock do
        if @job.requeueable?
          @job.update(locked_by: nil, locked_at: nil, failed_at: nil, last_error: nil, cancellation_requested_at: nil)
          flash[:notice] = 'Delayed Job re-queued'
        end
      end
      redirect_to admin_delayed_jobs_path
    end

    def cancel
      @job.with_lock do
        if @job.cancellable?
          @job.update(cancellation_requested_at: Time.current)
          flash[:notice] = 'Job cancellation requested'
        end
      end
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
