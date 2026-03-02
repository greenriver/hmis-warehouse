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

RSpec.describe 'SubmitForm for Inventory', type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:coc) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-500', user: u1 }
  let!(:inventory) { create :hmis_hud_inventory, data_source: ds1, project: p1, coc_code: coc.coc_code, inventory_start_date: '2020-01-01', inventory_end_date: nil, user: u1 }

  before(:each) { hmis_login(user) }

  let(:definition) { Hmis::Form::Definition.find_by(role: :INVENTORY) }
  let(:hud_values) do
    {
      'cocCode' => 'CO-500',
      'householdType' => 'HOUSEHOLDS_WITH_AT_LEAST_ONE_ADULT_AND_ONE_CHILD',
      'availability' => 'SEASONAL',
      'esBedType' => 'OTHER',
      'inventoryStartDate' => '2023-01-23',
      'inventoryEndDate' => nil,
      'unitInventory' => 0,
      'bedInventory' => 0,
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

  it_behaves_like 'submit form creates form processor'
  it_behaves_like 'submit form fails when required field is missing'
  it_behaves_like 'submit form fails when form definition is draft'
  it_behaves_like 'submit form updates user correctly'

  it 'saves a new inventory record' do
    record, = submit_form(input)
    inventory = Hmis::Hud::Inventory.find(record['id'])
    expect(inventory.coc_code).to eq('CO-500')
    expect(inventory.household_type).to eq(3) # HOUSEHOLDS_WITH_AT_LEAST_ONE_ADULT_AND_ONE_CHILD
    expect(inventory.availability).to eq(2) # SEASONAL
    expect(inventory.es_bed_type).to eq(3) # OTHER
    expect(inventory.inventory_start_date).to eq(Date.parse('2023-01-23'))
    expect(inventory.inventory_end_date).to be nil
  end

  it 'persists submitted form values to an existing inventory record' do
    expect do
      submit_form(input.merge(record_id: inventory.id))
      inventory.reload
    end.to change(inventory, :household_type).to(3) # HOUSEHOLDS_WITH_AT_LEAST_ONE_ADULT_AND_ONE_CHILD
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
