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
      household_type: Types::HmisSchema::Enums::Hud::HouseholdType.enum_member_for_value(4).first,
      availability: Types::HmisSchema::Enums::Hud::Availability.enum_member_for_value(2).first,
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
            #{scalar_fields(Types::HmisSchema::Inventory)}
          }
          #{error_fields}
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
        expect(errors.length).to eq(1)
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
        expect(errors.length).to eq(1)
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

    it 'fails if end date is before start date' do
      response, result = post_graphql(id: i1.id, input: { **valid_input, inventory_start_date: '2010-01-01', inventory_end_date: '2000-01-01' }) { mutation }

      record = result.dig('data', 'updateInventory', 'inventory')
      errors = result.dig('data', 'updateInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_present
        expect(record).to be_nil
        expect(errors.length).to eq(1)
        expect(errors[0]['attribute']).to eq 'inventoryEndDate'
        expect(errors[0]['type']).to eq 'invalid'
      end
    end

    it 'fails if counts are negaitve' do
      response, result = post_graphql(id: i1.id, input: { **valid_input, unit_inventory: -1, bed_inventory: -2, other_bed_inventory: -3 }) { mutation }

      record = result.dig('data', 'updateInventory', 'inventory')
      errors = result.dig('data', 'updateInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_present
        expect(record).to be_nil
        expect(errors.length).to eq(3)
        expect(errors[0]['attribute']).to eq 'bedInventory'
        expect(errors[0]['type']).to eq 'invalid'
      end
    end

    it 'validates start date against project operating period (start date too early)' do
      p1.update(operating_start_date: '2019-01-01')
      response, result = post_graphql(id: i1.id, input: { **valid_input, inventory_start_date: '2010-01-01' }) { mutation }

      record = result.dig('data', 'updateInventory', 'inventory')
      errors = result.dig('data', 'updateInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_present
        expect(record).to be_nil
        expect(errors.length).to eq(1)
        expect(errors[0]['attribute']).to eq 'inventoryStartDate'
        expect(errors[0]['type']).to eq 'invalid'
      end
    end

    it 'validates end date against project operating period (end date too late)' do
      p1.update(operating_start_date: '2019-01-01')
      p1.update(operating_end_date: '2019-02-01')
      response, result = post_graphql(id: i1.id, input: { **valid_input, inventory_start_date: '2019-01-01', inventory_end_date: '2019-03-01' }) { mutation }

      record = result.dig('data', 'updateInventory', 'inventory')
      errors = result.dig('data', 'updateInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_present
        expect(record).to be_nil
        expect(errors.length).to eq(1)
        expect(errors[0]['attribute']).to eq 'inventoryEndDate'
        expect(errors[0]['type']).to eq 'invalid'
      end
    end

    it 'validates both dates against project operating period (start date too early, with end date)' do
      p1.update(operating_start_date: '2019-01-01')
      p1.update(operating_end_date: '2019-02-01')
      response, result = post_graphql(id: i1.id, input: { **valid_input, inventory_start_date: '2018-01-01', inventory_end_date: '2019-01-15' }) { mutation }

      record = result.dig('data', 'updateInventory', 'inventory')
      errors = result.dig('data', 'updateInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_present
        expect(record).to be_nil
        expect(errors.length).to eq(1)
        expect(errors[0]['attribute']).to eq 'inventoryStartDate'
        expect(errors[0]['type']).to eq 'invalid'
      end
    end

    it 'validates both dates against project operating period (fully outside range)' do
      p1.update(operating_start_date: '2019-01-01')
      p1.update(operating_end_date: '2019-02-01')
      response, result = post_graphql(id: i1.id, input: { **valid_input, inventory_start_date: '2020-01-01', inventory_end_date: '2020-03-01' }) { mutation }

      record = result.dig('data', 'updateInventory', 'inventory')
      errors = result.dig('data', 'updateInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_present
        expect(record).to be_nil
        expect(errors.length).to eq(2)
        expect(errors[0]['attribute']).to eq 'inventoryStartDate'
        expect(errors[0]['type']).to eq 'invalid'
        expect(errors[1]['attribute']).to eq 'inventoryEndDate'
        expect(errors[1]['type']).to eq 'invalid'
      end
    end

    it 'validates both dates against project operating period (fully outside range in other direction)' do
      p1.update(operating_start_date: '2019-01-01')
      p1.update(operating_end_date: '2019-02-01')
      response, result = post_graphql(id: i1.id, input: { **valid_input, inventory_start_date: '2010-01-01', inventory_end_date: '2010-03-01' }) { mutation }

      record = result.dig('data', 'updateInventory', 'inventory')
      errors = result.dig('data', 'updateInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_present
        expect(record).to be_nil
        expect(errors.length).to eq(2)
        expect(errors[0]['attribute']).to eq 'inventoryStartDate'
        expect(errors[0]['type']).to eq 'invalid'
        expect(errors[1]['attribute']).to eq 'inventoryEndDate'
        expect(errors[1]['type']).to eq 'invalid'
      end
    end

    it 'passes validation if dates match project operating period' do
      p1.update(operating_start_date: '2019-01-01')
      p1.update(operating_end_date: '2019-02-01')
      response, result = post_graphql(id: i1.id, input: { **valid_input, inventory_start_date: '2019-01-01', inventory_end_date: '2019-02-01' }) { mutation }

      record = result.dig('data', 'updateInventory', 'inventory')
      errors = result.dig('data', 'updateInventory', 'errors')

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_empty
        expect(record).to be_present
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
