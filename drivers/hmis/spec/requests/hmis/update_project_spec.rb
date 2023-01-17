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

  let(:u2) do
    user2 = create(:user).tap { |u| u.add_viewable(ds1) }
    hmis_user2 = Hmis::User.find(user2.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) }
    Hmis::Hud::User.from_user(hmis_user2)
  end

  let(:edit_access_group) { create :edit_access_group }
  let(:view_access_group) { create :view_access_group }

  let(:test_input) do
    {
      project_name: 'Project 1',
      operating_start_date: (Date.yesterday).strftime('%Y-%m-%d'),
      operating_end_date: Date.current.strftime('%Y-%m-%d'),
      description: 'This is a test project',
      contact_information: 'Contact for contact information',
      project_type: Types::HmisSchema::Enums::ProjectType.enum_member_for_value(2).first,
      housing_type: Types::HmisSchema::Enums::Hud::HousingType.enum_member_for_value(3).first,
      tracking_method: Types::HmisSchema::Enums::Hud::TrackingMethod.enum_member_for_value(3).first,
      target_population: Types::HmisSchema::Enums::Hud::TargetPopulation.enum_member_for_value(4).first,
      'HOPWAMedAssistedLivingFac' => Types::HmisSchema::Enums::Hud::HOPWAMedAssistedLivingFac.enum_member_for_value(0).first,
      continuum_project: false,
      residential_affiliation: true,
      'HMISParticipatingProject' => false,
    }
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateProject($id: ID!, $input: ProjectInput!, $confirmed: Boolean!) {
        updateProject(input: { input: $input, id: $id, confirmed: $confirmed }) {
          project {
            #{scalar_fields(Types::HmisSchema::Project)}
            organization {
              id
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  describe 'with edit access' do
    before(:each) do
      hmis_login(user)
      assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
      p1.update(user_id: u2.user_id)
    end

    it 'should update a project successfully' do
      prev_date_updated = p1.date_updated
      aggregate_failures 'checking response' do
        expect(p1.user_id).to eq(u2.user_id)
        response, result = post_graphql(id: p1.id, input: test_input, confirmed: false) { mutation }

        expect(response.status).to eq 200
        project = result.dig('data', 'updateProject', 'project')
        errors = result.dig('data', 'updateProject', 'errors')
        expect(p1.reload.date_updated > prev_date_updated).to eq(true)
        expect(p1.user_id).to eq(u1.user_id)
        expect(errors).to be_empty
        expect(project).to include(
          'id' => p1.id.to_s,
          'organization' => { 'id' => o1.id.to_s },
          'projectName' => test_input[:project_name],
          'projectType' => test_input[:project_type],
          'HMISParticipatingProject' => test_input['HMISParticipatingProject'],
          'HOPWAMedAssistedLivingFac' => test_input['HOPWAMedAssistedLivingFac'],
          'contactInformation' => test_input[:contact_information],
          'continuumProject' => test_input[:continuum_project],
          'description' => test_input[:description],
          'housingType' => test_input[:housing_type],
          'operatingEndDate' => test_input[:operating_end_date],
          'operatingStartDate' => test_input[:operating_start_date],
          'residentialAffiliation' => test_input[:residential_affiliation],
          'targetPopulation' => test_input[:target_population],
          'trackingMethod' => test_input[:tracking_method],
        )
      end
    end

    it 'should allow nulls, and correctly nullify fields' do
      p1.update(description: 'foo', operating_end_date: '2022-01-01', housing_type: 3, continuum_project: 0, residential_affiliation: 1, HMISParticipatingProject: 99)
      input = {
        operating_end_date: nil,
        description: nil,
        housing_type: nil,
        continuum_project: nil,
        residential_affiliation: nil,
        'HMISParticipatingProject' => nil,
      }
      response, result = post_graphql(id: p1.id, input: input, confirmed: false) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        project = result.dig('data', 'updateProject', 'project')
        errors = result.dig('data', 'updateProject', 'errors')
        expect(errors).to be_empty
        expect(project).to include(
          'id' => p1.id.to_s,
          'HMISParticipatingProject' => input['HMISParticipatingProject'],
          'continuumProject' => input[:continuum_project],
          'description' => input[:description],
          'housingType' => input[:housing_type],
          'operatingEndDate' => input[:operating_end_date],
          'residentialAffiliation' => input[:residential_affiliation],
        )
        p1.reload
        expect(p1.operating_end_date).to be_nil
        expect(p1.description).to be_nil
        expect(p1.housing_type).to be_nil
        expect(p1.continuum_project).to eq(99)
        expect(p1.residential_affiliation).to eq(99)
        expect(p1.HMISParticipatingProject).to eq(99)
      end
    end

    it 'should fail if any fields are INVALID' do
      input = {
        project_type: 'INVALID',
        housing_type: 'INVALID',
      }
      response, result = post_graphql(id: p1.id, input: input, confirmed: false) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        errors = result.dig('data', 'updateProject', 'errors')
        expect(errors.length).to eq(2)
        expect(errors[0]['attribute']).to eq('projectType')
        expect(errors[0]['type']).to eq('invalid')
        expect(errors[1]['attribute']).to eq('housingType')
        expect(errors[1]['type']).to eq('invalid')
      end
    end
  end

  describe 'with related records' do
    before(:each) do
      hmis_login(user)
      assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
    end

    let!(:pc1) { create :hmis_hud_project_coc, data_source_id: ds1.id, project: p1, coc_code: 'CO-500' }
    let!(:i1) { create :hmis_hud_inventory, data_source: ds1, project: p1, coc_code: pc1.coc_code, inventory_start_date: '2020-01-01' }
    let!(:f1) { create :hmis_hud_funder, data_source_id: ds1.id, project: p1 }

    it 'should warn if closing project with open funders and inventory' do
      p1.update!(operating_end_date: nil)

      input = { operating_end_date: Date.today.strftime('%Y-%m-%d') }
      response, result = post_graphql(id: p1.id, input: input, confirmed: false) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        project = result.dig('data', 'updateProject', 'project')
        errors = result.dig('data', 'updateProject', 'errors')
        expect(project).to be_nil
        expect(p1.operating_end_date).to be_nil
        expect(errors.length).to eq(2)
      end
    end

    it 'should close related funders and inventory if confirmed' do
      p1.update!(operating_end_date: nil)

      end_date = Date.today.strftime('%Y-%m-%d')
      input = { operating_end_date: end_date }
      response, result = post_graphql(id: p1.id, input: input, confirmed: true) { mutation }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        project = result.dig('data', 'updateProject', 'project')
        errors = result.dig('data', 'updateProject', 'errors')
        expect(errors).to be_empty
        expect(project).to include('operatingEndDate' => end_date)
        expect(p1.reload.operating_end_date).to be_present
        expect(i1.reload.inventory_end_date).to be_present
        expect(f1.reload.end_date).to be_present
      end
    end
  end

  describe 'with view access' do
    before(:each) do
      hmis_login(user)
      assign_viewable(view_access_group, p1.as_warehouse, hmis_user)
      p1.update(user_id: u2.user_id)
    end

    it 'should not be able to update a project' do
      prev_date_updated = p1.date_updated
      aggregate_failures 'checking response' do
        expect(p1.user_id).to eq(u2.user_id)
        response, = post_graphql(id: p1.id, input: test_input, confirmed: false) { mutation }
        expect(response.status).to eq 200
        expect(p1.reload.date_updated > prev_date_updated).to eq(false)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
