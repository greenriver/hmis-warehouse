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
  let!(:pc2) { create :hmis_hud_project_coc, data_source_id: ds1.id, project: p1, coc_code: 'CO-503' }

  let(:valid_input) do
    {
      project_id: p1.id,
      coc_code: pc2.coc_code,
      household_type: Types::HmisSchema::Enums::HouseholdType.enum_member_for_value(4).first,
      availability: Types::HmisSchema::Enums::Availability.enum_member_for_value(2).first,
      unit_inventory: 2,
      bed_inventory: 2,
      inventory_start_date: '2022-01-01',
    }
  end

  let!(:i1) { create :hmis_hud_inventory, data_source: ds1, project: p1, coc_code: pc1.coc_code }

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateInventory($id: ID!, $input: InventoryInput!) {
        updateInventory(input: { input: $input, id: $id }) {
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
          }
          errors {
            attribute
            type
            fullMessage
            message
          }
        }
      }
    GRAPHQL
  end

  describe 'inventory update' do
    before(:each) do
      hmis_login(user)
      assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
    end

    it 'updates inventory successfully' do
      response, result = post_graphql(id: i1.id, input: valid_input) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        record = result.dig('data', 'updateInventory', 'inventory')
        errors = result.dig('data', 'updateInventory', 'errors')
        expect(errors).to be_empty
        expect(record['id']).to be_present
        inventory = Hmis::Hud::Inventory.find(record['id'])
        expect(inventory.coc_code).to eq pc2.coc_code
      end
    end

    it 'fails if coc code is invalid' do
      response, result = post_graphql(id: i1.id, input: { **valid_input, coc_code: 'FL-512' }) { mutation }

      record = result.dig('data', 'updateInventory', 'inventory')
      errors = result.dig('data', 'updateInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(record).to be_nil
        expect(errors).to be_present
        expect(errors[0]['attribute']).to eq 'cocCode'
        expect(errors[0]['type']).to eq 'invalid'
      end
    end

    it 'fails if coc code is null' do
      response, result = post_graphql(id: i1.id, input: { **valid_input, coc_code: nil }) { mutation }

      record = result.dig('data', 'updateInventory', 'inventory')
      errors = result.dig('data', 'updateInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(record).to be_nil
        expect(errors).to be_present
        expect(errors[0]['attribute']).to eq 'cocCode'
        expect(errors[0]['type']).to eq 'required'
      end
    end

    it 'fails if start date is null' do
      response, result = post_graphql(id: i1.id, input: { **valid_input, inventory_start_date: nil }) { mutation }

      record = result.dig('data', 'updateInventory', 'inventory')
      errors = result.dig('data', 'updateInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(record).to be_nil
        expect(errors).to be_present
        expect(errors[0]['attribute']).to eq 'inventoryStartDate'
        expect(errors[0]['type']).to eq 'required'
      end
    end

    it 'fails if project is null' do
      response, result = post_graphql(id: i1.id, input: { **valid_input, project_id: nil }) { mutation }

      record = result.dig('data', 'updateInventory', 'inventory')
      errors = result.dig('data', 'updateInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_present
        expect(record).to be_nil
        expect(errors[0]['attribute']).to eq 'projectId'
        expect(errors[0]['type']).to eq 'required'
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
