###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, o1) }
  let!(:pc1) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'MA-500' }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }

  before(:each) do
    hmis_login(user)
  end

  let(:query) do
    <<~GRAPHQL
      query GetPickList($pickListType: PickListType!, $relationId: ID) {
        pickList(pickListType: $pickListType, relationId: $relationId) {
          code
          label
          secondaryLabel
          groupLabel
          groupCode
          initialSelected
        }
      }
    GRAPHQL
  end

  before do
    # Mock RELEVANT_COC_STATE response
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('RELEVANT_COC_STATE').and_return('VT')
  end

  it 'returns CoC pick list' do
    response, result = post_graphql(pick_list_type: 'COC') { query }
    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      expect(options[0]['code']).to be_present
    end
  end

  it 'returns project pick list' do
    response, result = post_graphql(pick_list_type: 'PROJECT') { query }
    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      expect(options[0]['code']).to eq(p1.id.to_s)
      expect(options[0]['label']).to eq(p1.project_name)
      expect(options[0]['groupLabel']).to eq(o1.organization_name)
    end
  end

  describe 'ENROLLABLE_PROJECTS lost' do
    it 'should return no projects if no permission' do
      remove_permissions(access_control, :can_enroll_clients)
      response, result = post_graphql(pick_list_type: 'ENROLLABLE_PROJECTS') { query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        options = result.dig('data', 'pickList')
        expect(options).to be_empty
      end
    end

    it 'should exclude projects without can_enroll_clients permission' do
      o2 = create(:hmis_hud_organization, data_source: ds1, user: u1)
      create_access_control(hmis_user, o2, without_permission: :can_enroll_clients)

      # Viewable but doesn't have enroll permissions, so should not be in pick list
      p2 = create(:hmis_hud_project, organization: o2, data_source: ds1, user: u1)
      # Not viewable at all, so should not be in pick list
      create(:hmis_hud_project, data_source: ds1, user: u1)
      expect(Hmis::Hud::Project.viewable_by(hmis_user)).to contain_exactly(p1, p2)
      response, result = post_graphql(pick_list_type: 'ENROLLABLE_PROJECTS') { query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        options = result.dig('data', 'pickList')
        # p1 should be the only project that is viewable and has the right perms
        expect(options).to contain_exactly(include('code' => p1.id.to_s))
      end
    end
  end

  it 'returns organization pick list' do
    response, result = post_graphql(pick_list_type: 'ORGANIZATION') { query }
    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      expect(options[0]['code']).to eq(o1.id.to_s)
      expect(options[0]['label']).to eq(o1.organization_name)
      expect(options[0]['groupLabel']).to be_nil
    end
  end

  it 'returns grouped living situation pick list' do
    response, result = post_graphql(pick_list_type: 'PRIOR_LIVING_SITUATION') { query }
    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      expect(options[0]['code']).to eq(Types::HmisSchema::Enums::Hud::LivingSituation.all_enum_value_definitions.find { |v| v.value == 16 }.graphql_name)
      expect(options[0]['label']).to eq(::HudUtility.living_situation(16))
      expect(options[0]['groupCode']).to eq('HOMELESS')
      expect(options[0]['groupLabel']).to eq('Homeless')
    end
  end

  it 'returns CoC pick list for RELEVANT_COC_STATE' do
    response, result = post_graphql(pick_list_type: 'COC') { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options[0]['code']).to eq('VT-500')
  end

  it 'returns CoC pick list for specified project' do
    response, result = post_graphql(pick_list_type: 'COC', relationId: p1.id.to_s) { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options.length).to eq(1)
    expect(options[0]['code']).to eq(pc1.coc_code)
    expect(options[0]['label']).to include(::HudUtility.cocs[pc1.coc_code])
    expect(options[0]['initialSelected']).to eq(true)
  end

  it 'returns states with RELEVANT_COC_STATE selected' do
    response, result = post_graphql(pick_list_type: 'STATE') { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options.detect { |o| o['initialSelected'] }['code']).to eq('VT')
  end

  it 'returns geocodes for RELEVANT_COC_STATE' do
    response, result = post_graphql(pick_list_type: 'GEOCODE') { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options[0]['code']).to eq('509001')
  end

  it 'returns grouped service type pick list' do
    response, result = post_graphql(pick_list_type: 'ALL_SERVICE_TYPES') { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options.length).to eq(Hmis::Hud::CustomServiceType.count)
    opt = Hmis::Hud::CustomServiceType.first.to_pick_list_option
    expect(options).to include(
      include(
        'code' => opt[:code],
        'label' => opt[:label],
        'groupCode' => opt[:group_code],
        'groupLabel' => opt[:group_label],
      ),
    )
  end

  it 'returns service category pick list' do
    response, result = post_graphql(pick_list_type: 'ALL_SERVICE_CATEGORIES') { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options.length).to eq(Hmis::Hud::CustomServiceCategory.count)
    opt = Hmis::Hud::CustomServiceCategory.first.to_pick_list_option
    expect(options).to include(
      include(
        'code' => opt[:code],
        'label' => opt[:label],
      ),
    )
  end

  describe 'Resolving available Service Types for a Project' do
    include_context 'hmis service setup'
    let(:bednight_service_type) do
      Hmis::Hud::CustomServiceType.where(hud_record_type: 200).first!
    end
    let(:bednight_service_category) { bednight_service_type.category }
    let(:service_form_definition) do
      Hmis::Form::Definition.where(role: :SERVICE).first
    end
    let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 9 }
    let!(:o2) { create :hmis_hud_organization, data_source: ds1 }
    let!(:p3) { create :hmis_hud_project, data_source: ds1, organization: o2, project_type: 11 }

    def picklist_option_codes(project)
      Types::Forms::PickListOption.options_for_type(
        'AVAILABLE_SERVICE_TYPES',
        user: hmis_user,
        relation_id: project.id,
      ).map { |opt| opt[:code] }
    end

    it 'is empty if there are no instances that specify custom service category or custom service type' do
      # Should return empty, because the instance does not specify a service type or category
      # There are no "defaults" allowed for services
      create(
        :hmis_form_instance,
        entity: p1,
        definition_identifier: service_form_definition.identifier,
      )
      expect(picklist_option_codes(p1)).to be_empty
      expect(picklist_option_codes(p2)).to be_empty
    end

    it 'works when instance is associated by service category and project type' do
      # Instance: use this service definition for BedNights in ES projects
      create(
        :hmis_form_instance,
        entity_type: 'ProjectType',
        entity_id: 1, # ES
        definition_identifier: service_form_definition.identifier,
        custom_service_category_id: bednight_service_category.id,
      )

      # ES project
      expect(picklist_option_codes(p1)).to contain_exactly(bednight_service_type.id.to_s)
      # PH project
      expect(picklist_option_codes(p2)).to be_empty
    end

    it 'works when instance is associated by service category and project' do
      # Instance: use this service definition for BedNights in this specific project (p2)
      create(
        :hmis_form_instance,
        entity: p2,
        definition_identifier: service_form_definition.identifier,
        custom_service_category_id: bednight_service_category.id,
      )
      expect(picklist_option_codes(p2)).to contain_exactly(bednight_service_type.id.to_s)
      expect(picklist_option_codes(p1)).to be_empty
    end

    it 'works when instance is associated by service type and organization' do
      # Instance: use this service definition for service type cst1 in organization o1
      create(
        :hmis_form_instance,
        entity: o1,
        definition_identifier: service_form_definition.identifier,
        custom_service_type: cst1,
      )
      expect(picklist_option_codes(p1)).to contain_exactly(cst1.id.to_s)
      expect(picklist_option_codes(p2)).to contain_exactly(cst1.id.to_s)
      expect(picklist_option_codes(p3)).to be_empty
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
