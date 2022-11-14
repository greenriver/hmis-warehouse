require 'rails_helper'
require_relative 'login_and_permissions'
require_relative 'hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'
  let!(:pc1) { create :hmis_hud_project_coc, data_source_id: ds1.id, project: p1, coc_code: 'CO-500' }
  let(:valid_input) do
    {
      project_id: p1.id,
      coc_code: pc1.coc_code,
      household_type: Types::HmisSchema::Enums::Hud::HouseholdType.enum_member_for_value(4).first,
      availability: Types::HmisSchema::Enums::Hud::Availability.enum_member_for_value(2).first,
      unit_inventory: 2,
      bed_inventory: 2,
      inventory_start_date: Date.today.strftime('%Y-%m-%d'),
      inventory_end_date: (Date.today + 1.year).strftime('%Y-%m-%d'),
    }
  end

  describe 'inventory creation' do
    before(:each) do
      hmis_login(user)
      assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
    end

    let(:mutation) do
      <<~GRAPHQL
        mutation CreateInventory($input: InventoryInput!) {
          createInventory(input: { input: $input }) {
            inventory {
              id
              cocCode
              availability
              bedInventory
              chVetBedInventory
              unitInventory
              esBedType
              householdType
              inventoryEndDate
              inventoryStartDate
              dateCreated
              dateUpdated
              dateDeleted
              active
            }
            errors {
              attribute
              type
            }
          }
        }
      GRAPHQL
    end

    it 'creates inventory successfully' do
      response, result = post_graphql(input: valid_input) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        record = result.dig('data', 'createInventory', 'inventory')
        errors = result.dig('data', 'createInventory', 'errors')
        expect(errors).to be_empty
        expect(record['id']).to be_present
        expect(record['active']).to eq(true)
        inventory = Hmis::Hud::Inventory.find(record['id'])
        expect(inventory.inventory_start_date).to be_present
      end
    end

    it 'fails if coc code is invalid' do
      response, result = post_graphql(input: { **valid_input, coc_code: 'FL-501' }) { mutation }

      record = result.dig('data', 'createInventory', 'inventory')
      errors = result.dig('data', 'createInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(record).to be_nil
        expect(errors).to be_present
        expect(errors[0]['attribute']).to eq 'cocCode'
        expect(errors[0]['type']).to eq 'invalid'
      end
    end

    it 'fails if coc code is missing' do
      response, result = post_graphql(input: { **valid_input, coc_code: nil }) { mutation }

      record = result.dig('data', 'createInventory', 'inventory')
      errors = result.dig('data', 'createInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(record).to be_nil
        expect(errors).to be_present
        expect(errors[0]['attribute']).to eq 'cocCode'
        expect(errors[0]['type']).to eq 'required'
      end
    end

    it 'fails if start date is missing' do
      response, result = post_graphql(input: { **valid_input, inventory_start_date: nil }) { mutation }

      record = result.dig('data', 'createInventory', 'inventory')
      errors = result.dig('data', 'createInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(record).to be_nil
        expect(errors).to be_present
        expect(errors[0]['attribute']).to eq 'inventoryStartDate'
        expect(errors[0]['type']).to eq 'required'
      end
    end

    it 'fails if project is missing' do
      response, result = post_graphql(input: { **valid_input, project_id: nil }) { mutation }

      record = result.dig('data', 'createInventory', 'inventory')
      errors = result.dig('data', 'createInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(record).to be_nil
        expect(errors).to be_present
        expect(errors[0]['attribute']).to eq 'projectId'
        expect(errors[0]['type']).to eq 'required'
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
