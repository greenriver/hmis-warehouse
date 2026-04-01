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

RSpec.describe 'SubmitForm for Service', type: :request do
  include_context 'hmis base setup'
  include_context 'hmis json forms seed'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  before(:each) { hmis_login(user) }

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2020-01-01' }

  let(:service_type) { Hmis::Hud::CustomServiceType.find_by(hud_record_type: 200) } # created in the json forms seed context
  let(:definition) { Hmis::Form::Definition.find_by(role: :SERVICE) }

  let!(:service) { create :hmis_hud_service_bednight, data_source: ds1, client: c1, enrollment: e1, user: u1 }
  let(:hmis_service) { Hmis::Hud::HmisService.find_by(owner: service) }

  let(:hud_values) do
    {
      'otherTypeProvided' => '_HIDDEN',
      'movingOnOtherType' => 'something',
      'subTypeProvided' => '_HIDDEN',
      'faAmount' => '_HIDDEN',
      'faStartDate' => '_HIDDEN',
      'referralOutcome' => '_HIDDEN',
      'dateProvided' => '2023-03-15',
    }.stringify_keys
  end

  let(:input) do
    {
      form_definition_id: definition.id,
      enrollment_id: e1.id,
      service_type_id: service_type.id,
      hud_values: hud_values,
      values: hud_values_to_values_by_link_id(hud_values),
    }
  end

  it_behaves_like 'submit form marks enrollment for re-processing' do
    let(:enrollment) { e1 }
  end
  it_behaves_like 'submit form updates HUD User on record'

  it 'saves a new HUD service' do
    record, = submit_form(input)
    service = Hmis::Hud::HmisService.find(record['id'])
    expect(service.hud_service?).to be true
    expect(service.date_provided).to eq(Date.parse('2023-03-15'))
    expect(service.record_type).to eq(200)
    expect(service.moving_on_other_type).to eq('something')
  end

  # special case (don't use shared example) because the owner is the underlying Hmis::Hud::Service, not the Hmis::Hud::HmisService
  it 'creates a form processor' do
    record, = submit_form(input)
    record = definition.owner_class.find(record['id'])
    owner = record.owner
    expect(Hmis::Form::FormProcessor.where(owner: owner).count).to eq(1)
    expect(owner.form_processor).to be_present
  end

  it 'persists submitted form values to an existing service' do
    expect do
      submit_form(input.merge(record_id: hmis_service.id))
      service.reload
    end.to change(service, :date_provided).to(Date.parse('2023-03-15'))
  end

  context 'when user lacks can_edit_enrollments permission' do
    before { remove_permissions(access_control, :can_edit_enrollments) }

    it 'returns access denied' do
      expect_gql_error submit_form(input, expect_raise: true), message: /not authorized/
    end
  end

  describe 'custom service' do
    let!(:definition) do
      create :hmis_form_definition, role: :SERVICE, data_source: ds1, definition: {
        'item' => [
          {
            'type' => 'STRING',
            'link_id' => 'dateProvided',
            'mapping' => { 'field_name' => 'dateProvided' },
          },
          {
            'type' => 'STRING',
            'link_id' => 'myNotes',
            'text' => 'Notes',
            'mapping' => { 'custom_field_key' => 'myNotes' },
          },
        ],
      }
    end

    let!(:service) { create :hmis_custom_service, data_source: ds1, client: c1, enrollment: e1, user: u1, custom_service_type: cst1 }

    let(:hud_values) do
      {
        'dateProvided' => '2023-03-15',
        'myNotes' => 'Some notes',
      }.stringify_keys
    end

    let(:input) do
      {
        form_definition_id: definition.id,
        enrollment_id: e1.id,
        service_type_id: cst1.id,
        hud_values: hud_values,
        values: hud_values_to_values_by_link_id(hud_values),
      }
    end

    it 'saves a new custom service' do
      record, = submit_form(input)
      service = Hmis::Hud::HmisService.find(record['id'])
      expect(service.custom_service?).to be true
      expect(service.date_provided).to eq(Date.parse('2023-03-15'))
      expect(service.record_type).to eq(cst1.hud_record_type)
      expect(service.owner.custom_data_elements.sole.value_string).to eq('Some notes')
    end

    it 'persists submitted form values to an existing service' do
      expect do
        submit_form(input.merge(record_id: hmis_service.id))
        service.reload
      end.to change(service, :date_provided).to(Date.parse('2023-03-15'))
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
  c.include SubmitFormSpecHelpers
end
