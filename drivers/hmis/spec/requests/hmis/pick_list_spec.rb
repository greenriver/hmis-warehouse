###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  # before(:all) do
  #   cleanup_test_environment
  # end
  # after(:all) do
  #   cleanup_test_environment
  # end

  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, o1) }
  let!(:pc1) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'MA-500' }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }

  before(:each) do
    hmis_login(user)
  end

  let(:query) do
    <<~GRAPHQL
      query GetPickList($pickListType: PickListType!, $projectId: ID, $clientId: ID, $householdId: ID, $enrollmentId: ID) {
        pickList(pickListType: $pickListType, projectId: $projectId, clientId: $clientId, householdId: $householdId, enrollmentId: $enrollmentId) {
          code
          label
          secondaryLabel
          groupLabel
          groupCode
          initialSelected
          disabled
        }
      }
    GRAPHQL
  end

  before do
    # Mock RELEVANT_COC_STATE response
    allow(GrdaWarehouse::Config).to receive(:get).and_call_original
    allow(GrdaWarehouse::Config).to receive(:get).with(:relevant_state_codes).and_return('VT')
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

  describe 'ENROLLABLE_PROJECTS list' do
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
      expect(options[0]['code']).to eq(Types::HmisSchema::Enums::Hud::PriorLivingSituation.all_enum_value_definitions.find { |v| v.value == 101 }.graphql_name)
      expect(options[0]['label']).to eq(::HudUtility2024.living_situation(101))
      expect(options[0]['groupCode']).to eq('HOMELESS')
      expect(options[0]['groupLabel']).to eq('Homeless Situations')
    end
  end

  it 'returns CoC pick list for RELEVANT_COC_STATE' do
    response, result = post_graphql(pick_list_type: 'COC') { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options[0]['code']).to eq('VT-500')
  end

  it 'returns CoC pick list for specified project' do
    response, result = post_graphql(pick_list_type: 'COC', projectId: p1.id.to_s) { query }
    expect(response.status).to eq 200
    options = result.dig('data', 'pickList')
    expect(options.length).to eq(1)
    expect(options[0]['code']).to eq(pc1.coc_code)
    expect(options[0]['label']).to include(::HudUtility2024.cocs[pc1.coc_code])
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
    expected_size = JSON.parse(File.read('drivers/hmis/lib/pick_list_data/geocodes/geocodes-VT.json')).size
    expect(options.size).to eq(expected_size)
  end

  context 'when there are multiple relevant states' do
    before do
      GrdaWarehouse::Config.instance_variable_set(:@relevant_state_codes, nil) # reset the cached instance variable
      allow(GrdaWarehouse::Config).to receive(:get).with(:relevant_state_codes).and_return('VT,MA')
    end

    it 'returns geocodes grouped by state' do
      response, result = post_graphql(pick_list_type: 'GEOCODE') { query }
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      vt_size = JSON.parse(File.read('drivers/hmis/lib/pick_list_data/geocodes/geocodes-VT.json')).size
      ma_size = JSON.parse(File.read('drivers/hmis/lib/pick_list_data/geocodes/geocodes-MA.json')).size
      expect(options.size).to eq(vt_size + ma_size)
      expect(options.first['groupLabel']).to eq('VT')
      expect(options.last['groupLabel']).to eq('MA')
    end

    it 'returns states with no state auto-selected' do
      response, result = post_graphql(pick_list_type: 'STATE') { query }
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      expect(options.none? { |o| o['initialSelected'] }).to be_truthy
    end
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

  describe 'when there are both HUD and custom service categories' do
    let!(:hud_category) { create :hmis_custom_service_category, data_source: ds1, name: 'HUD category' }
    let!(:custom_category) { create :hmis_custom_service_category, data_source: ds1, name: 'Custom category' }
    let!(:hud_type) { create :hmis_custom_service_type, custom_service_category: hud_category, data_source: ds1, name: 'HUD type', hud_record_type: 141, hud_type_provided: 1 }
    let!(:custom_type) { create :hmis_custom_service_type, custom_service_category: custom_category, data_source: ds1, name: 'Custom type' }

    it 'returns custom-only service category pick list' do
      response, result = post_graphql(pick_list_type: 'CUSTOM_SERVICE_CATEGORIES') { query }
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      expect(options.length).to eq(Hmis::Hud::CustomServiceCategory.non_hud.count)
      expect(options.pluck('code')).to include(custom_category.id.to_s)
      expect(options.pluck('code')).not_to include(hud_category.id.to_s)
    end
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
        project_id: project.id,
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
        entity: nil,
        project_type: 1, # ES
        definition_identifier: service_form_definition.identifier,
        custom_service_category_id: bednight_service_category.id,
      )

      # ES project
      expect(picklist_option_codes(p1)).to contain_exactly(bednight_service_type.id.to_s)
      # PH project
      expect(picklist_option_codes(p2)).to be_empty
    end

    it 'works when instance is associated by service category and funder' do
      # Instance: use this service definition for funder 43 projects
      create(
        :hmis_form_instance,
        entity: nil,
        funder: 43,
        definition_identifier: service_form_definition.identifier,
        custom_service_category_id: bednight_service_category.id,
      )

      create(:hmis_hud_funder, funder: 43, project: p1, data_source: p1.data_source)
      expect(picklist_option_codes(p1)).to contain_exactly(bednight_service_type.id.to_s)
      expect(picklist_option_codes(p2)).to be_empty
    end

    it 'works when instance is associated by service category and Project Type AND Funder' do
      # Instance: use this service definition for projets of type 12 funded by 43
      create(
        :hmis_form_instance,
        entity: nil,
        project_type: 12,
        funder: 43,
        definition_identifier: service_form_definition.identifier,
        custom_service_category_id: bednight_service_category.id,
      )

      p1.update(project_type: 12)
      p2.update(project_type: 1)
      p3.update(project_type: 12)
      create(:hmis_hud_funder, funder: 43, project: p1, data_source: p1.data_source)
      create(:hmis_hud_funder, funder: 43, project: p2, data_source: p2.data_source)
      expect(picklist_option_codes(p1)).to contain_exactly(bednight_service_type.id.to_s)
      expect(picklist_option_codes(p2)).to be_empty # funder matches, type doesn't
      expect(picklist_option_codes(p3)).to be_empty # type matches, funder doesn't
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

  describe 'unit picklists' do
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
    let!(:br1) { create :hmis_unit_type, description: '1 BR' }
    let!(:br2) { create :hmis_unit_type, description: '2 BR' }

    let!(:un1) { create :hmis_unit, project: p1, unit_type: br1 }
    let!(:un2) { create :hmis_unit, project: p1, unit_type: br1 }
    let!(:un3) { create :hmis_unit, project: p1, unit_type: br2 }

    # cruft: units in other projects
    let!(:un4) { create :hmis_unit, unit_type: br1 }
    let!(:un5) { create :hmis_unit, unit_type: br2 }
    let!(:un6) { create :hmis_unit }

    # assign e1 to un1
    let!(:uo1) { create :hmis_unit_occupancy, unit: un1, enrollment: e1, start_date: 1.week.ago }

    def picklist_option_codes(project, picklist: 'AVAILABLE_UNITS_FOR_ENROLLMENT', household_id: nil)
      Types::Forms::PickListOption.options_for_type(
        picklist,
        user: hmis_user,
        project_id: project.id,
        household_id: household_id,
      ).map { |opt| opt[:code] }
    end

    context 'AVAILABLE_UNITS_FOR_ENROLLMENT' do
      it 'resolves available units for project' do
        expect(picklist_option_codes(p1)).to contain_exactly(un2.id, un3.id)
      end

      it 'includes units that are currently occupied by the household, plus other units of the same type' do
        result = picklist_option_codes(p1, household_id: e1.household_id)
        expect(result).to contain_exactly(un1.id, un2.id)
      end

      it 'if household unit doesn\'t have a type, includes all available units' do
        un1.update!(unit_type: nil)
        expect(picklist_option_codes(p1, household_id: e1.household_id)).to contain_exactly(un1.id, un2.id, un3.id)
      end
    end

    context 'ADMIN_AVAILABLE_UNITS_FOR_ENROLLMENT' do
      it 'resolves available units for project' do
        expect(picklist_option_codes(p1)).to contain_exactly(un2.id, un3.id)
      end

      it 'includes units with differing unit types' do
        expect(picklist_option_codes(p1, picklist: 'ADMIN_AVAILABLE_UNITS_FOR_ENROLLMENT', household_id: e1.household_id)).to contain_exactly(un1.id, un2.id, un3.id)
      end
    end
  end

  describe 'EXTERNAL_FORM_TYPES_FOR_PROJECT' do
    let!(:external_form) { create :hmis_form_definition, identifier: 'test-external', role: :EXTERNAL_FORM }

    context 'when form rule applies to a project' do
      let!(:rule) { create :hmis_form_instance, definition_identifier: 'test-external', entity: p1, active: true }

      it 'should return the external form for the project' do
        response, result = post_graphql(pick_list_type: 'EXTERNAL_FORM_TYPES_FOR_PROJECT', projectId: p1.id) { query }
        expect(response.status).to eq 200
        options = result.dig('data', 'pickList')
        expect(options.length).to eq(1)
        expect(options.first.dig('code')).to eq('test-external')
      end

      context 'but form is in draft' do
        let!(:external_form) { create :hmis_form_definition, identifier: 'test-external', role: :EXTERNAL_FORM, status: :draft }

        it 'should not return the draft form' do
          response, result = post_graphql(pick_list_type: 'EXTERNAL_FORM_TYPES_FOR_PROJECT', projectId: p1.id) { query }
          expect(response.status).to eq 200
          options = result.dig('data', 'pickList')
          expect(options.length).to eq(0)
        end
      end
    end
  end

  describe 'PROJECTS_RECEIVING_REFERRALS' do
    let!(:referral_dest_project) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
    let!(:referral_instance) { create :hmis_form_instance, role: :REFERRAL, entity: referral_dest_project }

    let!(:non_dest_project) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
    let!(:draft_referral_form) { create(:hmis_form_definition, role: :REFERRAL, identifier: 'bad-referral-form', status: :draft) }
    let!(:draft_referral_instance) { create :hmis_form_instance, role: :REFERRAL, definition_identifier: 'bad-referral-form', entity: non_dest_project }

    it 'should only return the project that has an active, non-draft instance' do
      response, result = post_graphql(pick_list_type: 'PROJECTS_RECEIVING_REFERRALS') { query }
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      expect(options.size).to eq(1)
      expect(options.first['code']).to eq(referral_dest_project.id.to_s)
    end
  end

  describe 'CE_WORKFLOW_TEMPLATE_IDENTIFIERS' do
    let!(:apples_retired) { create(:hmis_workflow_definition_template, identifier: 'apples', name: 'Apples 1', version: 0, status: :retired, data_source: ds1) }
    let!(:apples_published) { create(:hmis_workflow_definition_template, identifier: 'apples', name: 'Apples 2', version: 1, status: :published, data_source: ds1) }
    let!(:bananas_retired1) { create(:hmis_workflow_definition_template, identifier: 'bananas', name: 'Bananas 1', version: 0, status: :retired, data_source: ds1) }
    let!(:bananas_retired2) { create(:hmis_workflow_definition_template, identifier: 'bananas', name: 'Bananas 2', version: 1, status: :retired, data_source: ds1) }
    let!(:broccoli_not_ce) { create(:hmis_workflow_definition_template, identifier: 'broccoli', template_type: 'not_ce', data_source: ds1) }
    let!(:beans_retired_not_ce) { create(:hmis_workflow_definition_template, identifier: 'beans', status: :retired, template_type: 'not_ce', data_source: ds1) }
    let!(:coconut_wrong_data_source) { create(:hmis_workflow_definition_template, identifier: 'coconut', status: :published) }

    before(:each) do
      allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    end

    context 'published only' do
      let(:pick_list_type) { 'CE_WORKFLOW_TEMPLATE_IDENTIFIERS' }

      it 'should return all published templates, and not return non-ce or unpublished templates' do
        response, result = post_graphql(pick_list_type: pick_list_type) { query }
        expect(response.status).to eq 200
        options = result.dig('data', 'pickList')
        expect(options.size).to eq(1)
        expect(options).to contain_exactly(a_hash_including('code' => 'apples', 'label' => 'Apples 2'))
      end
    end

    context '_INCLUDING_RETIRED' do
      let(:pick_list_type) { 'CE_WORKFLOW_TEMPLATE_IDENTIFIERS_INCLUDING_RETIRED' }

      it 'should return all templates including fully retired workflows, and not return non-ce templates' do
        response, result = post_graphql(pick_list_type: pick_list_type) { query }
        expect(response.status).to eq 200
        options = result.dig('data', 'pickList')
        expect(options.size).to eq(2)
        expect(options).to contain_exactly(
          a_hash_including('code' => 'apples', 'label' => 'Apples 2'),
          a_hash_including('code' => 'bananas', 'label' => 'Bananas 2'),
        )
      end
    end
  end

  describe 'ELIGIBLE_REFERRAL_STEP_ASSIGNMENT_USERS' do
    let!(:project) { create(:hmis_hud_project, data_source: ds1) }

    let!(:admin_user) { hmis_user }
    let!(:ac1) { create_access_control(admin_user, project, with_permission: [:can_view_project, :can_perform_any_referral_tasks]) }
    let!(:user_who_can_perform_own_tasks) { create(:hmis_user, data_source: ds1) }
    let!(:ac2) { create_access_control(user_who_can_perform_own_tasks, project, with_permission: [:can_perform_own_referral_tasks]) }
    let!(:inactive_user_with_permission) { create(:hmis_user, data_source: ds1, active: false) }
    let!(:ac3) { create_access_control(inactive_user_with_permission, project, with_permission: [:can_view_project, :can_perform_any_referral_tasks]) }
    let!(:user_without_permission) { create(:hmis_user, data_source: ds1) }

    before(:each) do
      allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    end

    it 'returns eligible users and not ineligible users' do
      response, result = post_graphql(pick_list_type: 'ELIGIBLE_REFERRAL_STEP_ASSIGNMENT_USERS', project_id: project.id.to_s) { query }
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      expect(options).to contain_exactly(
        a_hash_including('code' => hmis_user.id.to_s),
        a_hash_including('code' => user_who_can_perform_own_tasks.id.to_s),
      )
    end
  end

  describe 'PROJECTS_ACCEPTING_CE_REFERRALS' do
    let!(:sending_project) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }
    let!(:receiving_project) { create(:hmis_hud_project, data_source: ds1, user: u1) }
    let!(:non_ce_project) { create(:hmis_hud_project, data_source: ds1, user: u1) }
    let!(:receiving_ce_config) { create(:hmis_project_ce_config, project: receiving_project, accepts_direct_referrals: true) }

    before(:each) do
      allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    end

    it 'returns projects that accept direct referrals' do
      response, result = post_graphql(pick_list_type: 'PROJECTS_ACCEPTING_CE_REFERRALS', project_id: sending_project.id.to_s) { query }
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      expect(options.size).to eq(1)
      expect(options.first['code']).to eq(receiving_project.id.to_s)
      expect(options.first['label']).to eq(receiving_project.project_name)
    end

    context 'when project only supports waitlist referrals' do
      before do
        receiving_ce_config.update!(
          accepts_direct_referrals: false,
          supports_waitlist_referrals: true,
        )
      end

      it 'does not return the project' do
        response, result = post_graphql(pick_list_type: 'PROJECTS_ACCEPTING_CE_REFERRALS', project_id: sending_project.id.to_s) { query }
        expect(response.status).to eq 200
        options = result.dig('data', 'pickList')
        expect(options).to be_empty
      end
    end

    context 'when accepting project restricts direct referrals from specific projects' do
      let!(:allowed_sending_project) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }

      before do
        receiving_ce_config.update!(
          accepts_direct_referrals: true,
          accepts_direct_referrals_from: [allowed_sending_project.id],
        )
      end

      it 'returns the project when sending from an allowed project' do
        response, result = post_graphql(pick_list_type: 'PROJECTS_ACCEPTING_CE_REFERRALS', project_id: allowed_sending_project.id.to_s) { query }
        expect(response.status).to eq 200
        options = result.dig('data', 'pickList')
        expect(options.size).to eq(1)
        expect(options.first['code']).to eq(receiving_project.id.to_s)
      end

      it 'does not return the project when sending from a non-allowed project' do
        response, result = post_graphql(pick_list_type: 'PROJECTS_ACCEPTING_CE_REFERRALS', project_id: sending_project.id.to_s) { query }
        expect(response.status).to eq 200
        options = result.dig('data', 'pickList')
        expect(options).to be_empty
      end
    end
  end

  describe 'UNIT_GROUPS_FOR_PROJECT_CE_REFERRAL' do
    let!(:ce_project) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }
    let!(:ce_config) { create(:hmis_project_ce_config, project: ce_project, accepts_direct_referrals: true) }
    let!(:access_control) { create_access_control(hmis_user, ce_project.organization, with_permission: [:can_manage_outgoing_referrals]) }

    let!(:workflow_template) { create(:hmis_workflow_definition_template, data_source: ds1, template_type: 'ce_referral', status: 'published') }
    let!(:initiation_task) { create(:hmis_workflow_definition_user_task, template: workflow_template) }

    let!(:unit_group_with_units) { create(:hmis_unit_group, project: ce_project, name: 'Available Group', workflow_template: workflow_template) }
    let!(:unit_group_no_units) { create(:hmis_unit_group, project: ce_project, name: 'Empty Group', workflow_template: workflow_template) }
    let!(:unit_group_occupied) { create(:hmis_unit_group, project: ce_project, name: 'Occupied Group', workflow_template: workflow_template) }

    # Unit group with available units
    let!(:available_unit1) { create(:hmis_unit, project: ce_project, unit_group: unit_group_with_units) }
    let!(:opportunity1) { create(:hmis_ce_opportunity, unit: available_unit1, project: ce_project, data_source: ce_project.data_source, status: :open) }
    let!(:available_unit2) { create(:hmis_unit, project: ce_project, unit_group: unit_group_with_units) }
    let!(:opportunity2) { create(:hmis_ce_opportunity, unit: available_unit2, project: ce_project, data_source: ce_project.data_source, status: :open) }

    # Unit group with occupied units
    let!(:occupied_unit) { create(:hmis_unit, project: ce_project, unit_group: unit_group_occupied) }
    let!(:unit_occupancy) { create(:hmis_unit_occupancy, unit: occupied_unit, start_date: 1.week.ago) }

    before(:each) do
      allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    end

    shared_examples 'returns empty pick list' do
      it 'returns empty array' do
        response, result = post_graphql(pick_list_type: 'UNIT_GROUPS_FOR_PROJECT_CE_REFERRAL', project_id: ce_project.id.to_s) { query }
        expect(response.status).to eq(200), result.inspect
        options = result.dig('data', 'pickList')

        expect(options).to be_empty
      end
    end

    context 'with user who has can_manage_outgoing_referrals permission (even without can_view_project)' do
      it 'returns unit groups' do
        response, result = post_graphql(pick_list_type: 'UNIT_GROUPS_FOR_PROJECT_CE_REFERRAL', project_id: ce_project.id.to_s) { query }
        expect(response.status).to eq(200), result.inspect
        options = result.dig('data', 'pickList')

        expect(options.size).to eq(3) # Returns all unit groups, but disables the ones that have no availability
        expect(options).to contain_exactly(
          a_hash_including('code' => unit_group_with_units.id.to_s, 'label' => 'Available Group', 'secondaryLabel' => '2 available', 'disabled' => false),
          a_hash_including('code' => unit_group_no_units.id.to_s, 'label' => 'Empty Group', 'secondaryLabel' => '0 available', 'disabled' => true),
          a_hash_including('code' => unit_group_occupied.id.to_s, 'label' => 'Occupied Group', 'secondaryLabel' => '0 available', 'disabled' => true),
        )
      end
    end

    context 'with user who does not have can_manage_outgoing_referrals permission' do
      before { remove_permissions(access_control, :can_manage_outgoing_referrals) }

      it_behaves_like 'returns empty pick list'
    end

    context 'when project does not accept direct referrals' do
      let!(:ce_config) { create(:hmis_project_ce_config, project: ce_project, supports_waitlist_referrals: true, accepts_direct_referrals: false) }

      it_behaves_like 'returns empty pick list'
    end

    context 'when the project and the user are not in the same data source' do
      let!(:ce_project) { create(:hmis_hud_project) }
      let!(:workflow_template) { create(:hmis_workflow_definition_template, data_source: ce_project.data_source, template_type: 'ce_referral', status: 'published') }

      it_behaves_like 'returns empty pick list'
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
