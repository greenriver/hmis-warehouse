###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
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
      expect(options[0]['label']).to eq(::HudHelper.util.living_situation(101))
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
    expect(options[0]['label']).to include(::HudHelper.util.cocs[pc1.coc_code])
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

      context 'units with CE opportunities and referrals' do
        let!(:project) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
        let!(:unit_with_open_opportunity) { create :hmis_unit, project: project, unit_type: br1 }
        let!(:unit_with_locked_opportunity) { create :hmis_unit, project: project, unit_type: br1 }
        let!(:unit_with_closed_opportunity) { create :hmis_unit, project: project, unit_type: br1 }

        let!(:open_opportunity) { create(:hmis_ce_opportunity, unit: unit_with_open_opportunity, status: :open) }
        let!(:locked_opportunity) { create(:hmis_ce_opportunity, unit: unit_with_locked_opportunity, status: :locked) }
        let!(:closed_opportunity) { create(:hmis_ce_opportunity, unit: unit_with_closed_opportunity, status: :closed) }

        it 'does not include unit with open or locked opportunities' do
          available_units = picklist_option_codes(project)
          expect(available_units).to contain_exactly(unit_with_closed_opportunity.id)
          expect(available_units).not_to include(unit_with_locked_opportunity.id, unit_with_open_opportunity.id)
        end
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
    let!(:external_form) { create :hmis_form_definition, identifier: 'test-external', role: :EXTERNAL_FORM, data_source: ds1 }

    context 'when form rule applies to a project' do
      let!(:rule) { create :hmis_form_instance, definition_identifier: 'test-external', entity: p1, active: true, data_source: ds1 }

      it 'should return the external form for the project' do
        response, result = post_graphql(pick_list_type: 'EXTERNAL_FORM_TYPES_FOR_PROJECT', projectId: p1.id) { query }
        expect(response.status).to eq 200
        options = result.dig('data', 'pickList')
        expect(options.length).to eq(1)
        expect(options.first.dig('code')).to eq('test-external')
      end

      context 'but form is in draft' do
        let!(:external_form) { create :hmis_form_definition, identifier: 'test-external', role: :EXTERNAL_FORM, status: :draft, data_source: ds1 }

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
    let!(:referral_instance) { create :hmis_form_instance, role: :REFERRAL, entity: referral_dest_project, data_source: ds1 }

    let!(:non_dest_project) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
    let!(:draft_referral_form) { create(:hmis_form_definition, role: :REFERRAL, identifier: 'bad-referral-form', status: :draft, data_source: ds1) }
    let!(:draft_referral_instance) { create :hmis_form_instance, role: :REFERRAL, definition_identifier: 'bad-referral-form', entity: non_dest_project, data_source: ds1 }

    it 'should only return the project that has an active, non-draft instance' do
      response, result = post_graphql(pick_list_type: 'PROJECTS_RECEIVING_REFERRALS') { query }
      expect(response.status).to eq(200), result.inspect
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
    let!(:project_config) { create(:hmis_project_ce_config, project: project, supports_waitlist_referrals: true) }

    let!(:admin_user) { hmis_user }
    let!(:ac1) { create_access_control(admin_user, ds1, with_permission: [:can_view_project, :can_perform_any_referral_tasks]) }
    let!(:user_who_can_perform_own_tasks) { create(:hmis_user, data_source: ds1) }
    let!(:ac2) { create_access_control(user_who_can_perform_own_tasks, project, with_permission: [:can_perform_own_referral_tasks]) }
    let!(:user_who_can_perform_any_task_at_project) { create(:hmis_user, data_source: ds1) }
    let!(:ac3) { create_access_control(user_who_can_perform_any_task_at_project, project, with_permission: [:can_view_project, :can_perform_any_referral_tasks]) }

    # Cruft: inactive user is not returned
    let!(:inactive_user_with_permission) { create(:hmis_user, data_source: ds1, active: false) }
    let!(:ac4) { create_access_control(inactive_user_with_permission, project, with_permission: [:can_view_project, :can_perform_any_referral_tasks]) }

    # Cruft: user with no relevant permission is not returned
    let!(:user_without_permission) { create(:hmis_user, data_source: ds1) }

    # Cruft: user with permission in another data source is not returned
    let!(:other_ds) { create(:hmis_data_source) }
    let!(:other_ds_user) { create(:hmis_user, data_source: other_ds) }
    let!(:other_ds_access_control) { create_access_control(other_ds_user, other_ds, with_permission: [:can_perform_any_referral_tasks]) }

    before(:each) do
      allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    end

    it 'returns eligible users and not ineligible users' do
      response, result = post_graphql(pick_list_type: 'ELIGIBLE_REFERRAL_STEP_ASSIGNMENT_USERS', project_id: project.id.to_s) { query }
      expect(response.status).to eq(200), result.inspect
      options = result.dig('data', 'pickList')
      expect(options).to contain_exactly(
        a_hash_including('code' => hmis_user.id.to_s),
        a_hash_including('code' => user_who_can_perform_any_task_at_project.id.to_s),
        a_hash_including('code' => user_who_can_perform_own_tasks.id.to_s),
      )
    end

    it 'returns users who can perform any tasks in the data source when no project is passed' do
      response, result = post_graphql(pick_list_type: 'ELIGIBLE_REFERRAL_STEP_ASSIGNMENT_USERS') { query }
      expect(response.status).to eq(200), result.inspect
      options = result.dig('data', 'pickList')
      expect(options).to contain_exactly(
        a_hash_including('code' => hmis_user.id.to_s),
        a_hash_including('code' => user_who_can_perform_any_task_at_project.id.to_s),
      )
    end

    context 'with many permissioned users' do
      before do
        20.times do
          user = create(:hmis_user, data_source: ds1)
          project = create(:hmis_hud_project, data_source: ds1)
          create_access_control(user, project, with_permission: [:can_perform_any_referral_tasks])
        end
      end

      it 'makes a reasonable number of queries when querying for specific project' do
        expect do
          response, result = post_graphql(pick_list_type: 'ELIGIBLE_REFERRAL_STEP_ASSIGNMENT_USERS', project_id: project.id.to_s) { query }
          expect(response.status).to eq(200), result.inspect
        end.to make_database_queries(count: 15..25)
      end

      it 'makes a reasonable number of queries when querying for data source' do
        expect do
          response, result = post_graphql(pick_list_type: 'ELIGIBLE_REFERRAL_STEP_ASSIGNMENT_USERS') { query }
          expect(response.status).to eq(200), result.inspect
        end.to make_database_queries(count: 5..20)
      end
    end
  end

  describe 'PROJECTS_RECEIVING_DIRECT_CE_REFERRALS' do
    let!(:sending_project) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }
    let!(:receiving_project) { create(:hmis_hud_project, data_source: ds1, user: u1) }
    let!(:unit_group) { create(:hmis_unit_group, project: receiving_project, name: 'Receiving Group') }
    let!(:non_ce_project) { create(:hmis_hud_project, data_source: ds1, user: u1) }
    let!(:receiving_ce_config) { create(:hmis_project_ce_config, project: receiving_project, receives_direct_referrals: true) }

    before(:each) do
      allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    end

    it 'returns projects that accept direct referrals' do
      response, result = post_graphql(pick_list_type: 'PROJECTS_RECEIVING_DIRECT_CE_REFERRALS', project_id: sending_project.id.to_s) { query }
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      expect(options.size).to eq(1)
      expect(options.first['code']).to eq(receiving_project.id.to_s)
      expect(options.first['label']).to eq(receiving_project.project_name)
    end

    context 'when project is closed' do
      let!(:receiving_project) { create(:hmis_hud_project, data_source: ds1, user: u1, operating_end_date: 1.week.ago) }

      it 'excludes closed project' do
        response, result = post_graphql(pick_list_type: 'PROJECTS_RECEIVING_DIRECT_CE_REFERRALS', project_id: sending_project.id.to_s) { query }
        expect(response.status).to eq 200
        options = result.dig('data', 'pickList')
        expect(options.size).to eq(0)
      end
    end
    context 'when the sending project also receives' do
      let!(:sending_config) { create(:hmis_project_ce_config, project: sending_project, receives_direct_referrals: true) }
      let!(:sending_unit_group) { create(:hmis_unit_group, project: sending_project, name: 'Another Group') }

      it 'does not include that project' do
        response, result = post_graphql(pick_list_type: 'PROJECTS_RECEIVING_DIRECT_CE_REFERRALS', project_id: sending_project.id.to_s) { query }
        expect(response.status).to eq 200
        options = result.dig('data', 'pickList')
        expect(options.map { |o| o['code'] }).not_to include(sending_project.id.to_s)
      end
    end

    context 'when project only supports waitlist referrals' do
      before do
        receiving_ce_config.update!(
          receives_direct_referrals: false,
          supports_waitlist_referrals: true,
        )
      end

      it 'does not return the project' do
        response, result = post_graphql(pick_list_type: 'PROJECTS_RECEIVING_DIRECT_CE_REFERRALS', project_id: sending_project.id.to_s) { query }
        expect(response.status).to eq 200
        options = result.dig('data', 'pickList')
        expect(options).to be_empty
      end
    end

    context 'when accepting project restricts direct referrals from specific projects' do
      let!(:allowed_sending_project) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }

      before do
        receiving_ce_config.update!(
          receives_direct_referrals: true,
          receives_direct_referrals_from: [allowed_sending_project.id],
        )
      end

      it 'returns the project when sending from an allowed project' do
        response, result = post_graphql(pick_list_type: 'PROJECTS_RECEIVING_DIRECT_CE_REFERRALS', project_id: allowed_sending_project.id.to_s) { query }
        expect(response.status).to eq 200
        options = result.dig('data', 'pickList')
        expect(options.size).to eq(1)
        expect(options.first['code']).to eq(receiving_project.id.to_s)
      end

      it 'does not return the project when sending from a non-allowed project' do
        response, result = post_graphql(pick_list_type: 'PROJECTS_RECEIVING_DIRECT_CE_REFERRALS', project_id: sending_project.id.to_s) { query }
        expect(response.status).to eq 200
        options = result.dig('data', 'pickList')
        expect(options).to be_empty
      end
    end
  end

  describe 'UNIT_GROUPS_FOR_PROJECT_DIRECT_CE_REFERRAL' do
    let!(:ce_project) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }
    let!(:ce_config) { create(:hmis_project_ce_config, project: ce_project, receives_direct_referrals: true) }
    let!(:access_control) { create_access_control(hmis_user, ce_project.organization, with_permission: [:can_manage_outgoing_referrals]) }

    let!(:workflow_template) { create(:hmis_workflow_definition_template, :with_basic_tasks, data_source: ds1, template_type: 'ce_referral', status: 'published') }

    let!(:unit_group_with_units) { create(:hmis_unit_group, project: ce_project, name: 'Available Group', workflow_template: workflow_template) }
    let!(:unit_group_no_units) { create(:hmis_unit_group, project: ce_project, name: 'Empty Group', workflow_template: workflow_template) }
    let!(:unit_group_occupied) { create(:hmis_unit_group, project: ce_project, name: 'Occupied Group', workflow_template: workflow_template) }

    # Unit group in the project that doesn't point to a workflow template. (Cruft, not included in picklist)
    let!(:unit_group_with_no_template) { create(:hmis_unit_group, project: ce_project, name: 'No Template Group', workflow_template: nil) }

    # Unit group with available units
    let!(:available_unit1) { create(:hmis_unit, project: ce_project, unit_group: unit_group_with_units) }
    let!(:opportunity1) { create(:hmis_ce_opportunity, unit: available_unit1, status: :open) }
    let!(:available_unit2) { create(:hmis_unit, project: ce_project, unit_group: unit_group_with_units) }
    let!(:opportunity2) { create(:hmis_ce_opportunity, unit: available_unit2, status: :open) }

    # Unit group with occupied units
    let!(:occupied_unit) { create(:hmis_unit, project: ce_project, unit_group: unit_group_occupied) }
    let!(:unit_occupancy) { create(:hmis_unit_occupancy, unit: occupied_unit, start_date: 1.week.ago) }

    before(:each) do
      allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    end

    shared_examples 'returns empty pick list' do
      it 'returns empty array' do
        response, result = post_graphql(pick_list_type: 'UNIT_GROUPS_FOR_PROJECT_DIRECT_CE_REFERRAL', project_id: ce_project.id.to_s) { query }
        expect(response.status).to eq(200), result.inspect
        options = result.dig('data', 'pickList')

        expect(options).to be_empty
      end
    end

    context 'with user who has can_manage_outgoing_referrals permission (even without can_view_project)' do
      it 'returns unit groups' do
        response, result = post_graphql(pick_list_type: 'UNIT_GROUPS_FOR_PROJECT_DIRECT_CE_REFERRAL', project_id: ce_project.id.to_s) { query }
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
      let!(:ce_config) { create(:hmis_project_ce_config, project: ce_project, supports_waitlist_referrals: true, receives_direct_referrals: false) }

      it_behaves_like 'returns empty pick list'
    end

    context 'when the project and the user are not in the same data source' do
      let!(:ce_project) { create(:hmis_hud_project) }
      let!(:workflow_template) { create(:hmis_workflow_definition_template, data_source: ce_project.data_source, template_type: 'ce_referral', status: 'published') }

      it_behaves_like 'returns empty pick list'
    end
  end

  describe 'CE_REFERRAL_STATUSES' do
    before(:each) do
      allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
      CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(ds1)
    end
    let!(:custom_status) { create(:hmis_ce_custom_referral_status, data_source: ds1, name: 'Assigned Pending Review', key: 'assigned_pending_review') }

    it 'returns all custom referral statuses' do
      response, result = post_graphql(pick_list_type: 'CE_REFERRAL_STATUSES') { query }
      expect(response.status).to eq 200
      options = result.dig('data', 'pickList')
      expect(options.count).to eq(4)
      expect(options).to contain_exactly(
        a_hash_including('code' => 'accepted', 'label' => 'Accepted'),
        a_hash_including('code' => 'rejected', 'label' => 'Declined'),
        a_hash_including('code' => 'in_progress', 'label' => 'In Progress'),
        a_hash_including('code' => 'assigned_pending_review', 'label' => 'Assigned Pending Review'),
      )
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
