# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'
require_relative '../../support/submit_form_spec_helpers'
require_relative '../../support/shared_examples/submit_form'

RSpec.describe 'SubmitForm for CeEvent', type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2000-01-01' }
  let!(:evt1) { create :hmis_hud_event, data_source: ds1, client: c1, enrollment: e1, user: u1 }

  before(:each) { hmis_login(user) }

  let(:definition) { Hmis::Form::Definition.find_by(role: :CE_EVENT) }
  let(:hud_values) do
    {
      'eventDate' => '2023-08-12',
      'event' => 'REFERRAL_TO_JOINT_TH_RRH_PROJECT_UNIT_RESOURCE_OPENING',
      'probSolDivRrResult' => '_HIDDEN',
      'referralCaseManageAfter' => '_HIDDEN',
      'locationCrisisOrPhHousing' => 'test',
      'referralResult' => 'SUCCESSFUL_REFERRAL_CLIENT_ACCEPTED',
      'resultDate' => '2023-08-16',
    }
  end
  let(:input) do
    {
      form_definition_id: definition.id,
      hud_values: hud_values,
      values: hud_values_to_values_by_link_id(hud_values),
      enrollment_id: e1.id,
      confirmed: true,
    }
  end

  it_behaves_like 'submit form updates HUD User on record'

  it 'saves a new ce event' do
    record, = submit_form(input)
    event = Hmis::Hud::Event.find(record['id'])
    expect(event.event_date).to eq(Date.parse('2023-08-12'))
    expect(event.event).to eq(12) # Referral to joint TH RRH project unit resource opening
    expect(event.prob_sol_div_rr_result).to be_nil
    expect(event.referral_case_manage_after).to be_nil
    expect(event.location_crisis_or_ph_housing).to eq('test')
    expect(event.referral_result).to eq(1) # Successful referral client accepted
    expect(event.result_date).to eq(Date.parse('2023-08-16'))
  end

  it 'persists submitted form values to an existing event' do
    expect do
      submit_form(input.merge(record_id: evt1.id))
      evt1.reload
    end.to change(evt1, :event_date).to(Date.parse('2023-08-12'))
  end

  context 'when user lacks can_edit_enrollments permission' do
    before { remove_permissions(access_control, :can_edit_enrollments) }

    it 'returns access denied' do
      expect_gql_error submit_form(input, expect_raise: true), message: /not authorized/
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
  c.include SubmitFormSpecHelpers
end
