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
      unit_inventory: 0,
      bed_inventory: 0,
      inventory_start_date: Date.today.strftime('%Y-%m-%d'),
      inventory_end_date: (Date.today + 1.year).strftime('%Y-%m-%d'),
      beds_per_unit: 1,
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
              #{scalar_fields(Types::HmisSchema::Inventory)}
              units {
                nodesCount
                nodes {
                  #{scalar_fields(Types::HmisSchema::Unit)}
                  beds {
                    #{scalar_fields(Types::HmisSchema::Bed)}
                  }
                }
              }
              beds {
                nodesCount
                nodes {
                  #{scalar_fields(Types::HmisSchema::Bed)}
                  unit {
                    id
                  }
                }
              }
            }
            #{error_fields}
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

    it 'creates units and beds (4 beds per unit, beds overflow)' do
      input = { unit_inventory: 2, vet_bed_inventory: 3, other_bed_inventory: 6, bed_inventory: 9, beds_per_unit: 4 }
      response, result = post_graphql(input: { **valid_input, **input }) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        record = result.dig('data', 'createInventory', 'inventory')
        errors = result.dig('data', 'createInventory', 'errors')
        expect(errors).to be_empty
        expect(record['id']).to be_present
        expect(record['active']).to eq(true)
        expect(record['units']['nodesCount']).to eq(2)
        expect(record['units']['nodes'][0]['beds'].length).to eq(4)
        expect(record['units']['nodes'][1]['beds'].length).to eq(5)
        inventory = Hmis::Hud::Inventory.find(record['id'])
        expect(inventory.inventory_start_date).to be_present
        expect(inventory.units.count).to eq(2)
        expect(inventory.beds.count).to eq(9)
      end
    end

    it 'creates units and beds (1 bed per unit, exact fit)' do
      input = { unit_inventory: 3, vet_bed_inventory: 1, other_bed_inventory: 2, bed_inventory: 3, beds_per_unit: 1 }
      response, result = post_graphql(input: { **valid_input, **input }) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        record = result.dig('data', 'createInventory', 'inventory')
        errors = result.dig('data', 'createInventory', 'errors')
        expect(errors).to be_empty
        expect(record['id']).to be_present
        expect(record['active']).to eq(true)
        expect(record['units']['nodesCount']).to eq(3)
        expect(record['units']['nodes'][0]['beds'].length).to eq(1)
        expect(record['units']['nodes'][1]['beds'].length).to eq(1)
        expect(record['units']['nodes'][2]['beds'].length).to eq(1)
        inventory = Hmis::Hud::Inventory.find(record['id'])
        expect(inventory.inventory_start_date).to be_present
        expect(inventory.units.count).to eq(3)
        expect(inventory.beds.count).to eq(3)
      end
    end

    it 'creates units and beds (1 bed per unit, beds underfill)' do
      input = { unit_inventory: 3, vet_bed_inventory: 1, bed_inventory: 1, beds_per_unit: 1 }
      response, result = post_graphql(input: { **valid_input, **input }) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        record = result.dig('data', 'createInventory', 'inventory')
        errors = result.dig('data', 'createInventory', 'errors')
        expect(errors).to be_empty
        expect(record['id']).to be_present
        expect(record['active']).to eq(true)
        expect(record['units']['nodesCount']).to eq(3)
        expect(record['units']['nodes'][0]['beds'].length).to eq(1)
        expect(record['units']['nodes'][1]['beds'].length).to eq(0)
        expect(record['units']['nodes'][2]['beds'].length).to eq(0)
        inventory = Hmis::Hud::Inventory.find(record['id'])
        expect(inventory.inventory_start_date).to be_present
        expect(inventory.units.count).to eq(3)
        expect(inventory.beds.count).to eq(1)
      end
    end

    it 'creates units with no beds' do
      response, result = post_graphql(input: { **valid_input, unit_inventory: 2 }) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        record = result.dig('data', 'createInventory', 'inventory')
        errors = result.dig('data', 'createInventory', 'errors')
        expect(errors).to be_empty
        expect(record['id']).to be_present
        expect(record['active']).to eq(true)
        expect(record['units']['nodesCount']).to eq(2)
        expect(record['units']['nodes'][0]['beds'].length).to eq(0)
        inventory = Hmis::Hud::Inventory.find(record['id'])
        expect(inventory.inventory_start_date).to be_present
        expect(inventory.units.count).to eq(2)
        expect(inventory.beds.count).to eq(0)
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
