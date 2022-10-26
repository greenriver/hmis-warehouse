require 'rails_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:ds1) { create :hmis_data_source }
  let!(:user) { create(:user).tap { |u| u.add_viewable(ds1) } }
  let(:hmis_user) { Hmis::User.find(user.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) } }
  let(:u1) { Hmis::Hud::User.from_user(hmis_user) }
  let!(:o1) { create :hmis_hud_organization, data_source_id: ds1.id, user: u1 }
  let!(:p1) { create :hmis_hud_project, data_source_id: ds1.id, organization: o1, user: u1 }
  let!(:pc1) { create :hmis_hud_project_coc, data_source_id: ds1.id, project: p1, coc_code: 'CO-500' }
  let(:valid_input) do
    {
      project_id: p1.id,
      coc_code: pc1.coc_code,
      household_type: Types::HmisSchema::Enums::HouseholdType.enum_member_for_value(4).first,
      availability: Types::HmisSchema::Enums::Availability.enum_member_for_value(2).first,
      unit_inventory: 2,
      bed_inventory: 2,
      inventory_start_date: Date.today.strftime('%Y-%m-%d'),
      inventory_end_date: (Date.today + 1.year).strftime('%Y-%m-%d'),
    }
  end

  describe 'inventory creation' do
    before(:each) do
      post hmis_user_session_path(hmis_user: { email: user.email, password: user.password })
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

      expect(response.status).to eq 200
      record = result.dig('data', 'createInventory', 'inventory')
      errors = result.dig('data', 'createInventory', 'errors')
      expect(errors).to be_empty
      expect(record['id']).to be_present
      expect(record['active']).to eq(true)
      inventory = Hmis::Hud::Inventory.find(record['id'])
      expect(inventory.inventory_start_date).to be_present
    end

    it 'fails if coc code is invalid' do
      response, result = post_graphql(input: { **valid_input, coc_code: 'FL-501' }) { mutation }

      record = result.dig('data', 'createInventory', 'inventory')
      errors = result.dig('data', 'createInventory', 'errors')

      expect(response.status).to eq 200
      expect(record).to be_nil
      expect(errors).to be_present
      expect(errors[0]['attribute']).to eq 'cocCode'
      expect(errors[0]['type']).to eq 'invalid'
    end

    it 'fails if coc code is missing' do
      response, result = post_graphql(input: { **valid_input, coc_code: nil }) { mutation }

      record = result.dig('data', 'createInventory', 'inventory')
      errors = result.dig('data', 'createInventory', 'errors')

      expect(response.status).to eq 200
      expect(record).to be_nil
      expect(errors).to be_present
      expect(errors[0]['attribute']).to eq 'cocCode'
      expect(errors[0]['type']).to eq 'required'
    end

    it 'fails if start date is missing' do
      response, result = post_graphql(input: { **valid_input, inventory_start_date: nil }) { mutation }

      record = result.dig('data', 'createInventory', 'inventory')
      errors = result.dig('data', 'createInventory', 'errors')

      expect(response.status).to eq 200
      expect(record).to be_nil
      expect(errors).to be_present
      expect(errors[0]['attribute']).to eq 'inventoryStartDate'
      expect(errors[0]['type']).to eq 'required'
    end

    it 'fails if project is missing' do
      response, result = post_graphql(input: { **valid_input, project_id: nil }) { mutation }

      record = result.dig('data', 'createInventory', 'inventory')
      errors = result.dig('data', 'createInventory', 'errors')

      expect(response.status).to eq 200
      expect(record).to be_nil
      expect(errors).to be_present
      expect(errors[0]['attribute']).to eq 'projectId'
      expect(errors[0]['type']).to eq 'required'
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
