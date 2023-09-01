###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Hud::Project, type: :model do
  before(:all) do
    Hmis::Form::Instance.not_system.destroy_all
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:project) { create :hmis_hud_project }
  before(:each) do
    create(:hmis_hud_enrollment, project: project, data_source: project.data_source)
    create(:hmis_hud_project_coc, project: project, data_source: project.data_source)
    create(:hmis_hud_funder, project: project, data_source: project.data_source)
    create(:hmis_hud_inventory, project: project, data_source: project.data_source)
  end

  it 'preserves shared data after destroy' do
    project.destroy
    project.reload

    [
      :data_source,
      :organization,
      :user,
    ].each do |assoc|
      expect(project.send(assoc)).to be_present, "expected #{assoc} to be present"
    end
  end

  it 'destroys dependent data' do
    project.reload
    [
      :enrollments,
      :project_cocs,
      :inventories,
      :funders,
    ].each do |assoc|
      expect(project.send(assoc)).to be_present, "expected #{assoc} to be present"
    end

    project.destroy
    project.reload

    [
      :enrollments,
      :project_cocs,
      :inventories,
      :funders,
    ].each do |assoc|
      expect(project.send(assoc)).not_to be_present, "expected #{assoc} not to be present"
    end
  end

  describe 'data_collection_features' do
    let(:role) { :CURRENT_LIVING_SITUATION }

    def selected_instances
      res = project.data_collection_features.find { |os| os.role == role.to_s }
      return [] unless res.present?

      [res.instance]
    end

    it 'returns none if none' do
      expect(selected_instances.size).to eq(0)
    end

    it 'chooses default instance, prefers active > inactive' do
      default_inst = create(:hmis_form_instance, role: role, entity: nil)
      create(:hmis_form_instance, role: role, entity: nil, active: false) # not chosen

      expect(selected_instances).to contain_exactly(default_inst)
    end

    it 'chooses more specific instance (project type > default)' do
      create(:hmis_form_instance, role: role, entity: nil)
      create(:hmis_form_instance, role: role, entity: nil, active: false)
      inst_for_project_type = create(:hmis_form_instance, role: role, entity: nil, project_type: project.project_type)

      expect(selected_instances).to contain_exactly(inst_for_project_type)
    end

    it 'chooses more specific instance (project > project type > default)' do
      create(:hmis_form_instance, role: role, entity: nil)
      create(:hmis_form_instance, role: role, entity: nil, active: false)
      create(:hmis_form_instance, role: role, entity: nil, project_type: project.project_type)
      inst_for_project = create(:hmis_form_instance, role: role, entity: project)
      expect(selected_instances).to contain_exactly(inst_for_project)
    end

    it 'tie-breaks on date updated' do
      create(:hmis_form_instance, role: role, entity: nil)
      create(:hmis_form_instance, role: role, entity: nil, active: false)
      create(:hmis_form_instance, role: role, entity: nil, project_type: project.project_type)
      inst_for_project = create(:hmis_form_instance, role: role, entity: project)
      create(:hmis_form_instance, role: role, entity: project, updated_at: inst_for_project.updated_at - 1.day)
      expect(selected_instances).to contain_exactly(inst_for_project)
    end

    it 'returns more specific instance, even if 2 have different data_collected_about values' do
      create(:hmis_form_instance, role: role, entity: nil)
      inst_for_project = create(:hmis_form_instance, role: role, entity: project)
      create(:hmis_form_instance, data_collected_about: 'HOH', role: role, entity: nil, project_type: project.project_type)

      expect(selected_instances).to contain_exactly(inst_for_project)
    end

    it 'if all are inactive, includes the most specific inactive' do
      create(:hmis_form_instance, role: role, entity: nil, active: false)
      inst_for_project = create(:hmis_form_instance, role: role, entity: project, active: false)

      expect(selected_instances).to contain_exactly(inst_for_project)
    end
  end

  describe 'occurrence_point_form_instances' do
    let(:role) { :OCCURRENCE_POINT }

    def selected_instances
      project.occurrence_point_form_instances
    end

    it 'returns none if none' do
      expect(selected_instances.size).to eq(0)
    end

    it 'does not return inactive instance' do
      create(:hmis_form_instance, role: role, entity: project, active: false)

      expect(selected_instances.size).to eq(0)
    end

    it 'returns most specific instance per definition identifier' do
      mid_ptype = create(:hmis_form_instance, role: role, entity: nil, project_type: 13, definition_identifier: 'move_in_date')
      mid_project = create(:hmis_form_instance, role: role, entity: project, definition_identifier: mid_ptype.definition_identifier)

      doe_default = create(:hmis_form_instance, role: role, entity: nil, definition_identifier: 'date_of_engagement')
      doe_org = create(:hmis_form_instance, role: role, entity: project.organization, definition_identifier: doe_default.definition_identifier)

      expect(selected_instances).to contain_exactly(mid_project, doe_org)
    end
  end
end
