###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
# Include for roles that trigger IdentifyDuplicates job: CLIENT, NEW_CLIENT_ENROLLMENT.
RSpec.shared_examples 'submit form triggers IdentifyDuplicates job' do
  it 'triggers IdentifyDuplicates job' do
    Delayed::Job.jobs_for_class(['GrdaWarehouse::Tasks::IdentifyDuplicates']).delete_all

    expect do
      submit_form(input)
    end.to change(Delayed::Job, :count)

    expect(Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::IdentifyDuplicates').count).to be_positive
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
