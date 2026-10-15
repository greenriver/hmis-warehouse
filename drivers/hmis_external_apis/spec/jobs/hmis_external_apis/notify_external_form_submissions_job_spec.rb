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

  before do
    allow(HmisExternalApis::ConsumeExternalFormSubmissionsJob).to receive(:enabled?).and_return(true)
  end

  after { clear_enqueued_jobs }

  def external_form_for(project)
    create(:hmis_external_form_definition, data_source: ds1).tap do |fd|
      Hmis::Form::Instance.create!(definition: fd, entity: project, active: true)
    end
  end

  def submit(form = definition, **attrs)
    create(:hmis_external_form_submission, definition: form, reviewers_notified_at: nil, **attrs)
  end

  def reviewer(entities = p1, permissions: reviewer_permissions)
    create(:user).tap do |u|
      create_access_control(u.related_hmis_user(ds1), entities, with_permission: permissions)
    end
  end

  # Run the job and the mail jobs it enqueues; return the Messages created
  def run_job
    before_id = Message.maximum(:id) || 0
    perform_enqueued_jobs { described_class.perform_now }
    Message.where(id: before_id + 1..).order(:id).to_a
  end

  it 'emails each reviewer of an opted-in project, and nobody else' do
    other_reviewer = reviewer
    no_permission = reviewer(permissions: [:can_view_project])
    inactive = reviewer.tap { |u| u.update_columns(active: false) }
    submit

    messages = run_job

    expect(messages.map(&:user_id)).to contain_exactly(user.id, other_reviewer.id)
    expect(messages.map(&:user_id)).not_to include(no_permission.id, inactive.id)
    expect(messages.first.subject).to eq('New external form submissions to review')
    expect(messages.first.body).to include(p1.project_name, '1 new submission')
  end

  it 'does not email a user who can manage submissions but not view the project' do
    remove_permissions(access_control, :can_view_project)
    submit

    expect(run_job).to be_empty
  end

  it 'sends one email listing every project the reviewer can review' do
    p2 = create(:hmis_hud_project, data_source: ds1, organization: o1)
    assign_viewable(access_control, p2)
    create(:hmis_project_external_form_submission_notification_config, project: p2)
    submit
    submit(external_form_for(p2))

    messages = run_job

    expect(messages.size).to eq(1)
    expect(messages.first.body).to include(p1.project_name, p2.project_name)
  end

  it 'counts spam like any other new submission' do
    submit(spam_score: 0.1)
    submit(spam_score: 0.9)

    expect(run_job.sole.body).to include('2 new submissions')
  end

  it 'stamps reviewed submissions without counting them' do
    reviewed = submit(status: 'reviewed')

    expect(run_job).to be_empty
    expect(reviewed.reload.reviewers_notified_at).to be_present

    submit(status: 'reviewed')
    submit
    expect(run_job.sole.body).to include('1 new submission')
  end

  it 'only notifies about submissions ingested after a project opts in' do
    opt_in.destroy!
    old_submission = submit
    allow(Hmis::Hud::Project).to receive(:with_access).and_call_original

    expect(run_job).to be_empty
    expect(old_submission.reload.reviewers_notified_at).to be_present
    # the recipient loop doesn't run when no project has opted in
    expect(Hmis::Hud::Project).not_to have_received(:with_access)

    create(:hmis_project_external_form_submission_notification_config, project: p1)
    expect(run_job).to be_empty

    submit
    expect(run_job.sole.body).to include('1 new submission')
  end

  it 'applies an organization-level opt-in to its projects' do
    opt_in.destroy!
    create(:hmis_project_external_form_submission_notification_config, organization: o1)
    submit

    expect(run_job.size).to eq(1)
  end

  it 'applies a project-type opt-in to projects of that type' do
    opt_in.destroy!
    create(:hmis_project_external_form_submission_notification_config, project_type: p1.project_type, data_source: ds1)
    submit

    expect(run_job.size).to eq(1)
  end

  describe 'misconfigured forms' do
    before { allow(Sentry).to receive(:capture_message) }

    def expect_reported(reason, **extra)
      expect(Sentry).to have_received(:capture_message).with(/#{reason}/, extra: hash_including(extra))
    end

    it 'reports, stamps, and skips a form without exactly one active project instance' do
      p2 = create(:hmis_hud_project, data_source: ds1, organization: o1)
      # Validation prevents a second active project instance; simulate data that predates it
      Hmis::Form::Instance.new(definition: definition, entity: p2, active: true).save!(validate: false)
      orphan_form = create(:hmis_external_form_definition, data_source: ds1)
      submissions = [submit, submit(orphan_form)]

      expect(run_job).to be_empty
      expect(submissions.map { |s| s.reload.reviewers_notified_at }).to all(be_present)
      expect_reported('exactly one active project instance', definition_id: definition.id, instance_count: 2)
      expect_reported('exactly one active project instance', definition_id: orphan_form.id, instance_count: 0)
    end

    it 'reports and skips a soft-deleted form definition' do
      submission = submit
      definition.update_column(:deleted_at, Time.current)

      expect(run_job).to be_empty
      expect(submission.reload.reviewers_notified_at).to be_present
      expect_reported('form definition not found', definition_id: definition.id)
    end

    it 'reports and skips a form whose project was deleted' do
      submission = submit
      p1.update_column(:DateDeleted, Time.current)

      expect(run_job).to be_empty
      expect(submission.reload.reviewers_notified_at).to be_present
      expect_reported('project not found', definition_id: definition.id)
    end

    it 'still notifies other projects' do
      p2 = create(:hmis_hud_project, data_source: ds1, organization: o1)
      assign_viewable(access_control, p2)
      create(:hmis_project_external_form_submission_notification_config, project: p2)
      submit(create(:hmis_external_form_definition, data_source: ds1))
      submit(external_form_for(p2))

      expect(run_job.sole.body).to include(p2.project_name)
      expect(Sentry).to have_received(:capture_message).once
    end
  end

  it 'does not report a project that has not opted in' do
    allow(Sentry).to receive(:capture_message)
    opt_in.destroy!
    submit

    expect(run_job).to be_empty
    expect(Sentry).not_to have_received(:capture_message)
  end

  it 'sends nothing on a second run' do
    submit

    expect(run_job.size).to eq(1)
    expect(run_job).to be_empty
  end

  it 'sends nothing and stamps nothing when the compute phase raises, then sends once on the next run' do
    submission = submit
    allow(Hmis::Hud::Project).to receive(:with_access).and_raise('boom')

    expect { described_class.perform_now }.to raise_error('boom')
    expect(enqueued_jobs).to be_empty
    expect(submission.reload.reviewers_notified_at).to be_nil

    allow(Hmis::Hud::Project).to receive(:with_access).and_call_original
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

  it 'does nothing when external forms are disabled' do
    allow(HmisExternalApis::ConsumeExternalFormSubmissionsJob).to receive(:enabled?).and_return(false)
    submission = submit

    expect(run_job).to be_empty
    expect(submission.reload.reviewers_notified_at).to be_nil
  end
end
