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

RSpec.describe 'SubmitForm for Funder', type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:f1) { create :hmis_hud_funder, data_source: ds1, project: p1, user: u1, end_date: nil }

  before(:each) { hmis_login(user) }

  let(:definition) { Hmis::Form::Definition.find_by(role: :FUNDER) }
  let(:hud_values) do
    {
      'funder' => 'HUD_COC_TRANSITIONAL_HOUSING',
      'otherFunder' => '_HIDDEN',
      'grantId' => 'ABCDEF',
      'startDate' => '2022-12-01',
      'endDate' => nil,
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

  it_behaves_like 'submit form updates user correctly'

  it 'saves a new funder' do
    record, = submit_form(input)
    funder = Hmis::Hud::Funder.find(record['id'])
    expect(funder.funder).to eq(5)
    expect(funder.other_funder).to be nil
    expect(funder.grant_id).to eq('ABCDEF')
    expect(funder.start_date).to eq(Date.parse('2022-12-01'))
    expect(funder.end_date).to be nil
  end

  it 'persists submitted form values to an existing funder' do
    expect do
      submit_form(input.merge(record_id: f1.id))
      f1.reload
    end.to change(f1, :grant_id).to('ABCDEF')
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
