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

  # include_context 'hmis base setup'
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

  describe 'instances_for_role' do
    let(:role) { :CURRENT_LIVING_SITUATION }

    it 'returns none if none' do
      expect(project.instances_for_role(role).size).to eq(0)
    end

    it 'chooses default instance, prefers active > inactive' do
      default_inst = create(:hmis_form_instance, role: role, entity: nil)
      create(:hmis_form_instance, role: role, entity: nil, active: false) # not chosen

      expect(project.instances_for_role(role)).to contain_exactly(default_inst)
    end

    it 'chooses more specific instance (project type > default)' do
      create(:hmis_form_instance, role: role, entity: nil)
      create(:hmis_form_instance, role: role, entity: nil, active: false)
      inst_for_project_type = create(:hmis_form_instance, role: role, entity: nil, project_type: project.project_type)

      expect(project.instances_for_role(role)).to contain_exactly(inst_for_project_type)
    end

    it 'chooses more specific instance (project > project type > default)' do
      create(:hmis_form_instance, role: role, entity: nil)
      create(:hmis_form_instance, role: role, entity: nil, active: false)
      create(:hmis_form_instance, role: role, entity: nil, project_type: project.project_type)
      inst_for_project = create(:hmis_form_instance, role: role, entity: project)
      expect(project.instances_for_role(role)).to contain_exactly(inst_for_project)
    end

    it 'tie-breaks on date updated' do
      create(:hmis_form_instance, role: role, entity: nil)
      create(:hmis_form_instance, role: role, entity: nil, active: false)
      create(:hmis_form_instance, role: role, entity: nil, project_type: project.project_type)
      inst_for_project = create(:hmis_form_instance, role: role, entity: project)
      create(:hmis_form_instance, role: role, entity: project, updated_at: inst_for_project.updated_at - 1.day)
      expect(project.instances_for_role(role)).to contain_exactly(inst_for_project)
    end

    it 'returns 2 instances if they have different data_collected_about values' do
      create(:hmis_form_instance, role: role, entity: nil)
      inst_for_project = create(:hmis_form_instance, role: role, entity: project)
      inst_for_project_type = create(:hmis_form_instance, data_collected_about: 'HOH', role: role, entity: nil, project_type: project.project_type)

      expect(project.instances_for_role(role)).to contain_exactly(
        inst_for_project, # Chosen over default. Still included because data_collected_about = nil.
        inst_for_project_type, # Most specific for this data_collected_about group.
      )
    end

    it 'chooses active > inactive' do
      # only option for HOH
      inst_for_project_type = create(:hmis_form_instance, data_collected_about: 'HOH', role: role, entity: nil, project_type: project.project_type)

      # default, active
      default_inst = create(:hmis_form_instance, role: role, entity: nil)
      # more specific, but inactive
      create(:hmis_form_instance, role: role, entity: project, active: false)

      expect(project.instances_for_role(role)).to contain_exactly(
        default_inst, # Chosen over inst_for_project because its active, even though its less specific
        inst_for_project_type, # Most specific for this data_collected_about group.
      )
    end

    it 'if all are inactive, includes the most specific inactive' do
      create(:hmis_form_instance, role: role, entity: nil, active: false)
      inst_for_project_type = create(:hmis_form_instance, role: role, entity: nil, project_type: project.project_type, data_collected_about: 'HOH')
      inst_for_project = create(:hmis_form_instance, role: role, entity: project, active: false)

      expect(project.instances_for_role(role)).to contain_exactly(
        inst_for_project, # Chosen even though its inactive, because its the most specific option for this data_collected_about group.
        inst_for_project_type, # Most specific for this data_collected_about group.
      )
    end
  end
end
