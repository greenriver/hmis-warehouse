# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::DelayedJobsController, type: :request do
  let!(:user) { create(:acl_user) }
  let!(:admin_role) { create(:admin_role) }
  let!(:collection) { create(:collection) }
  let!(:job) { Delayed::Job.create!(handler: { 'job_class' => 'ApplicationJob', 'arguments' => [] }.to_yaml, run_at: 1.hour.from_now) }

  before do
    setup_access_control(user, admin_role, collection)
    sign_in user
  end

  after do
    Delayed::Job.delete_all
  end

  describe 'GET #index' do
    it 'renders the list of jobs successfully' do
      get admin_delayed_jobs_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(job.run_at.to_s)
    end

    it 'shows non-interruptible for running non-instrumented jobs' do
      job.update!(locked_at: Time.current, locked_by: 'worker')
      # Mock interruptible? to return false to simulate a non-instrumented job
      allow_any_instance_of(Delayed::Backend::ActiveRecord::Job).to receive(:interruptible?).and_return(false)

      get admin_delayed_jobs_path
      expect(response.body).to include('(non-interruptible)')
    end
  end

  describe 'PATCH #cancel' do
    it 'cancels the job' do
      patch cancel_admin_delayed_job_path(job)

      expect(response).to redirect_to(admin_delayed_jobs_path)
      expect(flash[:notice]).to eq('Job cancellation requested')

      job.reload
      expect(job.cancellation_requested_at).to be_present
    end

    it 'does not cancel if not cancellable' do
      job.update!(failed_at: Time.current)

      patch cancel_admin_delayed_job_path(job)
      expect(flash[:notice]).to be_nil

      job.reload
      expect(job.cancellation_requested_at).to be_nil
    end
  end

  describe 'PATCH #update' do
    it 're-queues the job if failed' do
      job.update!(locked_at: Time.current, locked_by: 'worker', failed_at: Time.current)
      patch admin_delayed_job_path(job)

      expect(response).to redirect_to(admin_delayed_jobs_path)
      expect(flash[:notice]).to eq('Delayed Job re-queued')

      job.reload
      expect(job.locked_at).to be_nil
      expect(job.locked_by).to be_nil
      expect(job.failed_at).to be_nil
    end

    it 're-queues the job if cancellation was requested' do
      job.update!(cancellation_requested_at: Time.current)
      patch admin_delayed_job_path(job)

      expect(flash[:notice]).to eq('Delayed Job re-queued')
      job.reload
      expect(job.cancellation_requested_at).to be_nil
    end

    it 'does not re-queue if not requeueable (e.g. just running)' do
      job.update!(locked_at: Time.current, locked_by: 'worker')
      patch admin_delayed_job_path(job)

      expect(flash[:notice]).to be_nil
      job.reload
      expect(job.locked_at).to be_present
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the job' do
      expect do
        delete admin_delayed_job_path(job)
      end.to change(Delayed::Job, :count).by(-1)

      expect(response).to redirect_to(admin_delayed_jobs_path)
      expect(flash[:notice]).to eq('Delayed Job deleted')
    end
  end
end
