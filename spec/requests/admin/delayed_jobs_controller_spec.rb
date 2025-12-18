# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::DelayedJobsController, type: :request do
  let!(:user) { create(:acl_user) }
  let!(:admin_role) { create(:admin_role) }
  let!(:collection) { create(:collection) }
  let!(:job) { Delayed::Job.create!(handler: 'some_handler', run_at: 1.hour.from_now) }

  before do
    setup_access_control(user, admin_role, collection)
    sign_in user
  end

  after do
    Delayed::Job.delete_all
  end

  describe 'GET #index' do
    it 'returns http success' do
      get admin_delayed_jobs_path
      expect(response).to have_http_status(:success)
    end

    it 'renders the list of jobs' do
      get admin_delayed_jobs_path
      expect(response.body).to include(job.run_at.to_s)
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
  end

  describe 'PATCH #update' do
    before do
      job.update!(locked_at: Time.current, locked_by: 'worker')
    end

    it 're-queues the job' do
      patch admin_delayed_job_path(job)

      expect(response).to redirect_to(admin_delayed_jobs_path)
      expect(flash[:notice]).to eq('Delayed Job re-queued')

      job.reload
      expect(job.locked_at).to be_nil
      expect(job.locked_by).to be_nil
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
