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
require_relative 'submit_form_spec'

RSpec.describe 'SubmitForm for CurrentLivingSituation', type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:c2) { create :hmis_hud_client_complete, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, user: u1, entry_date: '2000-01-01' }
  let!(:cls1) { create :hmis_current_living_situation, data_source: ds1, client: c2, enrollment: e1, user: u1 }

  before(:each) { hmis_login(user) }

  let(:definition) { Hmis::Form::Definition.find_by(role: :CURRENT_LIVING_SITUATION) }
  let(:hud_values) do
    {
      'informationDate' => '2023-07-27',
      'currentLivingSituation' => 'FOSTER_CARE_HOME_OR_FOSTER_CARE_GROUP_HOME',
      'clsSubsidyType' => '_HIDDEN',
      'leaveSituation14Days' => 'YES',
      'subsequentResidence' => 'NO',
      'resourcesToObtain' => 'CLIENT_PREFERS_NOT_TO_ANSWER',
      'leaseOwn60Day' => 'CLIENT_DOESN_T_KNOW',
      'movedTwoOrMore' => 'YES',
      'locationDetails' => 'test',
    }.stringify_keys
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

  it_behaves_like 'submit form creates form processor'
  it_behaves_like 'submit form marks enrollment for re-processing' do
    let(:enrollment) { e1 }
  end
  it_behaves_like 'submit form fails when required field is missing'
  it_behaves_like 'submit form fails when form definition is draft'
  it_behaves_like 'submit form updates user correctly'

  it 'saves a new current living situation' do
    record, = submit_form(input)
    current_living_situation = Hmis::Hud::CurrentLivingSituation.find(record['id'])
    expect(current_living_situation.information_date).to eq(Date.parse('2023-07-27'))
    expect(current_living_situation.current_living_situation).to eq(215) # FOSTER_CARE_HOME_OR_FOSTER_CARE_GROUP_HOME from COMPLETE_VALUES
    expect(current_living_situation.cls_subsidy_type).to be_nil
    expect(current_living_situation.leave_situation14_days).to eq(1)
  end

  it 'persists submitted form values to the existing current living situation' do
    expect do
      submit_form(input.merge(record_id: cls1.id))
      cls1.reload
    end.to change(cls1, :current_living_situation).to(215) # FOSTER_CARE_HOME_OR_FOSTER_CARE_GROUP_HOME from COMPLETE_VALUES
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
