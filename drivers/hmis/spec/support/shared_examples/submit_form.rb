###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../submit_form_spec_helpers'

# This file contains shared examples for SubmitForm behavior across roles.
# Used by submit_form_*_spec.rb files.

# Required lets: enrollment, input
# Include for roles that trigger enrollment reprocessing: ENROLLMENT, SERVICE, CURRENT_LIVING_SITUATION
RSpec.shared_examples 'submit form marks enrollment for re-processing' do
  it 'marks enrollment for re-processing' do
    Delayed::Job.jobs_for_class(['GrdaWarehouse::Tasks::ServiceHistory::Enrollment']).delete_all
    enrollment.update!(processed_as: 'PROCESSED', processed_hash: 'PROCESSED')

    expect do
      submit_form(input)
      enrollment.reload
    end.to change(enrollment, :processed_as).from('PROCESSED').to(nil).
      and change(enrollment, :processed_hash).from('PROCESSED').to(nil).
      and change(Delayed::Job, :count).by(1)

    expect(Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::ServiceHistory::Enrollment').count).to be_positive
  end
end

# Required lets: input.
# Include for roles that create a client: CLIENT, NEW_CLIENT_ENROLLMENT.
RSpec.shared_examples 'submit form triggers IdentifyDuplicates job' do
  it 'enqueues a per-client IdentifyDuplicates job on the short queue and no full run' do
    Delayed::Job.jobs_for_class(['GrdaWarehouse::Tasks::IdentifyDuplicates']).delete_all

    expect { submit_form(input) }.to change(Delayed::Job, :count)

    jobs = Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::IdentifyDuplicates')
    per_client_jobs = jobs.jobs_for_class('process_source_client!')
    expect(per_client_jobs.count).to eq(1)
    expect(jobs.jobs_for_class('run!')).to be_empty

    job = per_client_jobs.first
    expect(job.queue).to eq(ENV.fetch('DJ_SHORT_QUEUE_NAME', 'short_running'))
    expect(job.handler).to include("- #{Hmis::Hud::Client.order(:id).last.id}\n")
  end
end

# Required lets: definition, input, hmis_user
RSpec.shared_examples 'submit form updates HUD User on record' do
  it 'updates user correctly' do
    record, = submit_form(input)
    record = definition.owner_class.find(record['id'])
    expect(record.user).to eq(Hmis::Hud::User.from_user(hmis_user))

    next_input = input.merge(record_id: record.id)

    record, = submit_form(next_input)
    record = definition.owner_class.find(record['id'])

    expect(record.user).to eq(Hmis::Hud::User.from_user(hmis_user))
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
  c.include SubmitFormSpecHelpers
end
