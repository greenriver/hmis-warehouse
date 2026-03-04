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

RSpec.describe 'SubmitForm for HmisParticipation', type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:hmis_particip1) { create :hmis_hud_hmis_participation, HMISParticipationType: 0, data_source: ds1, project: p1, user: u1 }

  before(:each) { hmis_login(user) }

  let(:definition) { Hmis::Form::Definition.find_by(role: :HMIS_PARTICIPATION) }
  let(:hud_values) do
    {
      "hmisParticipationType": 'HMIS_PARTICIPATING',
      "hmisParticipationStatusStartDate": '2020-07-19',
      "hmisParticipationStatusEndDate": nil,
    }.stringify_keys
  end
  let(:input) do
    {
      form_definition_id: definition.id,
      hud_values: hud_values,
      values: hud_values_to_values_by_link_id(hud_values),
      project_id: p1.id,
      confirmed: true,
    }
  end

  it_behaves_like 'submit form updates HUD User on record'

  it 'saves a new hmis participation' do
    record, = submit_form(input)
    hmis_participation = Hmis::Hud::HmisParticipation.find(record['id'])
    expect(hmis_participation.hmis_participation_type).to eq(1) # HMIS_PARTICIPATING
    expect(hmis_participation.hmis_participation_status_start_date).to eq(Date.parse('2020-07-19'))
    expect(hmis_participation.hmis_participation_status_end_date).to be nil
  end

  it 'persists submitted form values to an existing hmis participation' do
    expect do
      submit_form(input.merge(record_id: hmis_particip1.id))
      hmis_particip1.reload
    end.to change(hmis_particip1, :hmis_participation_type).to(1) # HMIS_PARTICIPATING
  end

  context 'when user lacks can_edit_project_details permission' do
    before { remove_permissions(access_control, :can_edit_project_details) }

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
