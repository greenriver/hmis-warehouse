###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../hmis/spec/requests/hmis/login_and_permissions'
require_relative '../../../../hmis/spec/support/hmis_base_setup'

RSpec.describe HmisExternalApis::NotifyExternalFormSubmissionsJob, type: :model do
  include_context 'hmis base setup'
  include ActiveJob::TestHelper

  let(:reviewer_permissions) { [:can_manage_external_form_submissions, :can_view_project] }
  let!(:access_control) { create_access_control(hmis_user, p1, with_permission: reviewer_permissions) }

  let!(:definition) { external_form_for(p1) }
  let!(:opt_in) { create(:hmis_project_external_form_submission_notification_config, project: p1) }

  after { clear_enqueued_jobs }

  def external_form_for(project)
    create(:hmis_external_form_definition, data_source: ds1).tap do |fd|
      Hmis::Form::Instance.create!(definition: fd, entity: project, active: true)
    end
  end

  def submit(form = definition, **attrs)
    create(:hmis_external_form_submission, definition: form, **attrs)
  end

  def reviewer(permissions: reviewer_permissions)
    create(:user).tap do |u|
      create_access_control(u.related_hmis_user(ds1), p1, with_permission: permissions)
    end
  end

  # Run the job and the mail jobs it enqueues; return the Messages created
  def run_job(project = p1)
    before_id = Message.maximum(:id) || 0
    perform_enqueued_jobs { described_class.perform_now(project_id: project.id) }
    Message.where(id: before_id + 1..).order(:id).to_a
  end

  it 'emails each reviewer of the project, and nobody else' do
    other_reviewer = reviewer
    no_permission = reviewer(permissions: [:can_view_project])
    cannot_view_project = reviewer(permissions: [:can_manage_external_form_submissions])
    inactive = reviewer.tap { |u| u.update_columns(active: false) }
    submit

    messages = run_job

    expect(messages.map(&:user_id)).to contain_exactly(user.id, other_reviewer.id)
    expect(messages.map(&:user_id)).not_to include(no_permission.id, cannot_view_project.id, inactive.id)
    expect(messages.first.subject).to eq('New external form submissions to review')
    expect(messages.first.body).to include(p1.project_name, '1 new submission')
  end

  it 'does not email a user who reviews submissions only at a different project' do
    p2 = create(:hmis_hud_project, data_source: ds1, organization: o1)
    other_project_reviewer = create(:user)
    create_access_control(other_project_reviewer.related_hmis_user(ds1), p2, with_permission: reviewer_permissions)
    submit

    expect(run_job.map(&:user_id)).to contain_exactly(user.id)
  end

  it 'stamps reviewed submissions without counting them' do
    reviewed = submit(status: 'reviewed')

    expect(run_job).to be_empty
    expect(reviewed.reload.reviewers_notified_at).to be_present

    submit(status: 'reviewed')
    submit
    expect(run_job.sole.body).to include('1 new submission')
  end

  it 'stamps without emailing when the project has not opted in, so opting in later skips the backlog' do
    opt_in.destroy!
    old_submission = submit

    expect(run_job).to be_empty
    expect(old_submission.reload.reviewers_notified_at).to be_present

    create(:hmis_project_external_form_submission_notification_config, project: p1)
    expect(run_job).to be_empty

    submit
    expect(run_job.sole.body).to include('1 new submission')
  end

  it "leaves submissions outside the project's review queue alone" do
    p2 = create(:hmis_hud_project, data_source: ds1, organization: o1)
    other_project_submission = submit(external_form_for(p2))
    orphan_submission = submit(create(:hmis_external_form_definition, data_source: ds1))

    expect(run_job).to be_empty
    expect(other_project_submission.reload.reviewers_notified_at).to be_nil
    expect(orphan_submission.reload.reviewers_notified_at).to be_nil
  end

  it 'sends nothing on a second run' do
    submit

    expect(run_job.size).to eq(1)
    expect(run_job).to be_empty
  end

  it 'sends nothing and stamps nothing when finding recipients raises, then sends once on the next run' do
    submission = submit
    allow(Hmis::User).to receive(:can_manage_external_form_submissions_for).and_raise('boom')

    expect { described_class.perform_now(project_id: p1.id) }.to raise_error('boom')
    expect(enqueued_jobs).to be_empty
    expect(submission.reload.reviewers_notified_at).to be_nil

    allow(Hmis::User).to receive(:can_manage_external_form_submissions_for).and_call_original
    expect(run_job.size).to eq(1)
    expect(run_job).to be_empty
  end

  it 'never includes submission content in the email' do
    submit(raw_data: { 'your_name' => 'DISTINCTIVE-RAW-DATA-VALUE' }, notes: 'DISTINCTIVE-NOTES-VALUE')

    message = run_job.sole

    [message.subject, message.body].each do |text|
      expect(text).not_to include('DISTINCTIVE-RAW-DATA-VALUE')
      expect(text).not_to include('DISTINCTIVE-NOTES-VALUE')
    end
  end

  it 'creates an undelivered message for users on a daily digest' do
    user.update!(email_schedule: 'daily')
    submit

    message = run_job.sole
    expect(message.user_id).to eq(user.id)
    expect(message.sent_at).to be_nil
  end

  it "links to the project's External Forms page in the HMIS" do
    submit
    expect(run_job.sole.body).to include("/projects/#{p1.id}/external-form-submissions")
  end

  it 'does nothing when the project no longer exists' do
    submission = submit
    project = p1
    project.destroy!

    expect(run_job(project)).to be_empty
    expect(submission.reload.reviewers_notified_at).to be_nil
  end

  describe '.perform_later_for_review_projects' do
    it 'enqueues one job per project with an active external form' do
      p2 = create(:hmis_hud_project, data_source: ds1, organization: o1)
      external_form_for(p2)
      external_form_for(p2)
      p3 = create(:hmis_hud_project, data_source: ds1, organization: o1)
      Hmis::Form::Instance.create!(definition: create(:hmis_external_form_definition, data_source: ds1), entity: p3, active: false)

      described_class.perform_later_for_review_projects

      enqueued_project_ids = enqueued_jobs.map { |job| job[:args].first['project_id'] }
      expect(enqueued_project_ids).to contain_exactly(p1.id, p2.id)
    end
  end
end
