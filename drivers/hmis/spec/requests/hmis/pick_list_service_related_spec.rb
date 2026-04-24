###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'

RSpec.describe 'PickList service-related dropdowns', type: :request do
  include_context 'hmis base setup'
  let!(:access_control) { create_access_control(hmis_user, o1) }
  before(:each) { hmis_login(user) }

  let(:query) do
    <<~GRAPHQL
      query GetPickList($pickListType: PickListType!) {
        pickList(pickListType: $pickListType) {
          code
          label
          groupLabel
        }
      }
    GRAPHQL
  end

  # cruft: another data source with both custom and HUD service types/categories
  before(:all) do
    ds2 = create(:hmis_data_source, hmis: 'other-hmis')
    HmisUtil::ServiceTypes.seed_hud_service_types(ds2.id)
    HmisUtil::JsonForms.seed_all(data_source_id: ds2.id) # creates system form instances
    ds2_csc = create(:hmis_custom_service_category, data_source: ds2, name: 'Other HMIS Custom Cat')
    ds2_cst = create(:hmis_custom_service_type, custom_service_category: ds2_csc, data_source: ds2, name: 'Other HMIS Custom Type')
    create(:hmis_form_instance, data_source: ds2, custom_service_category: ds2_csc, definition: create(:hmis_form_definition, identifier: 'service_1', data_source: ds2, role: :SERVICE))
    create(:hmis_form_instance, data_source: ds2, custom_service_type: ds2_cst, definition: create(:hmis_form_definition, identifier: 'service_2', data_source: ds2, role: :SERVICE))
  end

  after(:all) do
    ds2 = GrdaWarehouse::DataSource.find_by!(hmis: 'other-hmis')
    Hmis::Form::Definition.in_data_source(ds2.id).delete_all
    Hmis::Form::Instance.in_data_source(ds2.id).delete_all
    Hmis::Hud::CustomDataElementDefinition.where(data_source: ds2).delete_all
    Hmis::Hud::CustomServiceCategory.where(data_source: ds2).delete_all
    Hmis::Hud::CustomServiceType.where(data_source: ds2).delete_all
    ds2.destroy!
  end

  describe 'service type and category pick lists' do
    include_context 'hmis service setup'

    let(:hud_only_category) { ds1.custom_service_categories.hud_only.order(:id).first }
    let(:hud_type) { ds1.custom_service_types.hud.order(:id).first }
    let!(:custom_only_category) { create :hmis_custom_service_category, data_source: ds1, user: u1, name: 'Custom Only Category' }
    let!(:custom_type_1) { create :hmis_custom_service_type, custom_service_category: custom_only_category, data_source: ds1, user: u1, name: 'Custom Type 1' }
    let!(:custom_type_2) { create :hmis_custom_service_type, custom_service_category: custom_only_category, data_source: ds1, user: u1, name: 'Custom Type 2' }

    describe 'ALL_SERVICE_TYPES' do
      it 'returns all service types' do
        response, result = post_graphql(pick_list_type: 'ALL_SERVICE_TYPES') { query }
        expect(response.status).to eq(200), result.inspect
        options = result.dig('data', 'pickList')

        expect(options.length).to eq(Hmis::Hud::CustomServiceType.in_data_source(ds1.id).count)
        expect(options.pluck('code')).to include(custom_type_1.id.to_s, hud_type.id.to_s)

        # Verify structure includes group label
        custom_option = options.find { |o| o['code'] == custom_type_1.id.to_s }
        expect(custom_option['label']).to eq('Custom Type 1')
        expect(custom_option['groupLabel']).to eq('Custom Only Category')
      end
    end

    describe 'CUSTOM_SERVICE_TYPES' do
      it 'returns only custom service types' do
        response, result = post_graphql(pick_list_type: 'CUSTOM_SERVICE_TYPES') { query }
        expect(response.status).to eq(200), result.inspect
        options = result.dig('data', 'pickList')

        expect(options.length).to eq(Hmis::Hud::CustomServiceType.in_data_source(ds1.id).custom.count)
        expect(options.pluck('code')).to include(custom_type_1.id.to_s, custom_type_2.id.to_s)
        expect(options.pluck('code')).not_to include(hud_type.id.to_s)
      end
    end

    describe 'HUD_SERVICE_TYPES' do
      it 'returns only HUD service types' do
        response, result = post_graphql(pick_list_type: 'HUD_SERVICE_TYPES') { query }
        expect(response.status).to eq(200), result.inspect
        options = result.dig('data', 'pickList')

        expect(options.length).to eq(Hmis::Hud::CustomServiceType.in_data_source(ds1.id).hud.count)
        expect(options.pluck('code')).to include(hud_type.id.to_s)
        expect(options.pluck('code')).not_to include(custom_type_1.id.to_s, custom_type_2.id.to_s)
      end
    end

    describe 'ALL_SERVICE_CATEGORIES' do
      it 'returns all service categories' do
        response, result = post_graphql(pick_list_type: 'ALL_SERVICE_CATEGORIES') { query }
        expect(response.status).to eq(200), result.inspect
        options = result.dig('data', 'pickList')

        expect(options.length).to eq(Hmis::Hud::CustomServiceCategory.in_data_source(ds1.id).count)
        expect(options.pluck('code')).to include(hud_only_category.id.to_s, custom_only_category.id.to_s)

        custom_option = options.find { |o| o['code'] == custom_only_category.id.to_s }
        expect(custom_option['label']).to eq('Custom Only Category')
      end
    end

    describe 'CUSTOM_SERVICE_CATEGORIES' do
      it 'returns only custom-only service categories' do
        response, result = post_graphql(pick_list_type: 'CUSTOM_SERVICE_CATEGORIES') { query }
        expect(response.status).to eq(200), result.inspect
        options = result.dig('data', 'pickList')

        expect(options.length).to eq(Hmis::Hud::CustomServiceCategory.in_data_source(ds1.id).custom_only.count)
        expect(options.pluck('code')).to include(custom_only_category.id.to_s)
        expect(options.pluck('code')).not_to include(hud_only_category.id.to_s)
      end
    end

    describe 'HUD_SERVICE_CATEGORIES' do
      it 'returns only HUD-only service categories' do
        response, result = post_graphql(pick_list_type: 'HUD_SERVICE_CATEGORIES') { query }
        expect(response.status).to eq(200), result.inspect
        options = result.dig('data', 'pickList')

        expect(options.length).to eq(Hmis::Hud::CustomServiceCategory.in_data_source(ds1.id).hud_only.count)
        expect(options.pluck('code')).to include(hud_only_category.id.to_s)
        expect(options.pluck('code')).not_to include(custom_only_category.id.to_s)

        expect(options.length).to eq(HudHelper.util.record_types.size)
        expect(options.map { |o| o['label'] }).to match_array(HudHelper.util.record_types.values)
      end
    end
  end

  describe 'Resolving available Service Types for a Project' do
    # This describe block does NOT seed HUD service types/projects; it tests from a blank slate, for clarity
    let(:service_form_definition) { create(:hmis_form_definition, role: :SERVICE, data_source: ds1) }
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
      expect(picklist_option_codes(p1)).to be_empty
      expect(picklist_option_codes(p2)).to be_empty
    end

    it 'works when instance is associated by service category and project type' do
      # Instance: use this service definition for csc1 (custom service category 1) in ES projects
      create(
        :hmis_form_instance,
        entity: nil,
        project_type: 1, # ES
        definition_identifier: service_form_definition.identifier,
        custom_service_category_id: csc1.id,
        data_source: ds1,
      )

      # ES project
      expect(picklist_option_codes(p1)).to contain_exactly(cst1.id.to_s)
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
        custom_service_category_id: csc1.id,
        data_source: ds1,
      )

      create(:hmis_hud_funder, funder: 43, project: p1, data_source: p1.data_source)
      expect(picklist_option_codes(p1)).to contain_exactly(cst1.id.to_s)
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
        custom_service_category_id: csc1.id,
        data_source: ds1,
      )

      p1.update(project_type: 12)
      p2.update(project_type: 1)
      p3.update(project_type: 12)
      create(:hmis_hud_funder, funder: 43, project: p1, data_source: p1.data_source)
      create(:hmis_hud_funder, funder: 43, project: p2, data_source: p2.data_source)
      expect(picklist_option_codes(p1)).to contain_exactly(cst1.id.to_s)
      expect(picklist_option_codes(p2)).to be_empty # funder matches, type doesn't
      expect(picklist_option_codes(p3)).to be_empty # type matches, funder doesn't
    end

    it 'works when instance is associated by service category and project' do
      # Instance: use this service definition for csc1 (custom service category 1) in this specific project (p2)
      create(
        :hmis_form_instance,
        entity: p2,
        definition_identifier: service_form_definition.identifier,
        custom_service_category_id: csc1.id,
        data_source: ds1,
      )
      expect(picklist_option_codes(p2)).to contain_exactly(cst1.id.to_s)
      expect(picklist_option_codes(p1)).to be_empty
    end

    it 'works when instance is associated by service type and organization' do
      # Instance: use this service definition for service type cst1 in organization o1
      create(
        :hmis_form_instance,
        entity: o1,
        definition_identifier: service_form_definition.identifier,
        custom_service_type: cst1,
        data_source: ds1,
      )
      expect(picklist_option_codes(p1)).to contain_exactly(cst1.id.to_s)
      expect(picklist_option_codes(p2)).to contain_exactly(cst1.id.to_s)
      expect(picklist_option_codes(p3)).to be_empty
    end
  end
end
