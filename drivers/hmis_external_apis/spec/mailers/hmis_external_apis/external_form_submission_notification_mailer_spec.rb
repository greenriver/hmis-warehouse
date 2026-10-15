###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../hmis/spec/support/hmis_base_setup'

RSpec.describe HmisExternalApis::ExternalFormSubmissionNotificationMailer, type: :mailer do
  include_context 'hmis base setup'
  include ActiveJob::TestHelper

  let(:project_counts) { { p1.id.to_s => 2 } }

  after { clear_enqueued_jobs }

  # Enqueue the email the way the notify job does, apply a change before it's delivered, then deliver it
  def deliver_after
    before_id = Message.maximum(:id) || 0
    described_class.new_submissions(
      user_id: user.id,
      data_source_id: ds1.id,
      project_counts: project_counts,
    ).deliver_later
    yield if block_given?
    perform_enqueued_jobs
    Message.where(id: before_id + 1..).to_a
  end

  it 'creates a message for an active user' do
    expect(deliver_after.sole.body).to include(p1.project_name, '2 new submissions')
  end

  it 'sends nothing when the user is deactivated before delivery' do
    expect(deliver_after { user.update_columns(active: false) }).to be_empty
  end

  it 'sends nothing when the user is deleted before delivery' do
    expect(deliver_after { user.destroy! }).to be_empty
  end

  it 'sends nothing when every project is gone before delivery' do
    expect(deliver_after { p1.destroy! }).to be_empty
  end
end
