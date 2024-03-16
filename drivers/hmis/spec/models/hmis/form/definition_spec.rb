###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Form::Definition, type: :model do
  include_context 'hmis base setup'

  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:fd1) { create :hmis_form_definition, role: 'INTAKE' }
  let!(:fi1) { create :hmis_form_instance, definition: fd1, entity: p1 }

  it 'should return the right definition if a project has a specific assessment' do
    expect(Hmis::Form::Definition.find_definition_for_role(fd1.role, project: p1)).to eq(fd1)
  end

  it 'should return the right definition if a project\'s org has a specific assessment' do
    fi1.entity = o1
    fi1.save!
    expect(Hmis::Form::Definition.find_definition_for_role(fd1.role, project: p1)).to eq(fd1)
  end

  it 'should return the right definition if a project\'s type has a specific assessment' do
    fi1.update(entity: nil, project_type: p1.project_type)
    expect(Hmis::Form::Definition.find_definition_for_role(fd1.role, project: p1)).to eq(fd1)
  end

  it 'should return the right definition if there\'s only a default assessment' do
    fi1.entity = nil
    fi1.save!
    expect(Hmis::Form::Definition.find_definition_for_role(fd1.role, project: p1)).to eq(fd1)
  end

  describe 'with multiple definitions' do
    let!(:fd2) { create :hmis_form_definition, role: 'UPDATE' }
    let!(:fi2) { create :hmis_form_instance, definition: fd2, entity: p1 }

    it 'should return a definition with the correct role' do
      expect(Hmis::Form::Definition.find_definition_for_role(fd1.role, project: p1)).to eq(fd1)
      expect(Hmis::Form::Definition.find_definition_for_role(fd2.role, project: p1)).to eq(fd2)
    end

    it 'should return the most specific definition with the correct role' do
      fi2.update(entity: nil, project_type: p1.project_type)
      fd2.update(role: fd1.role)
      expect(Hmis::Form::Definition.find_definition_for_role(fd1.role, project: p1)).to eq(fd1)
    end

    it 'should return the most recent version of a definition when no version provided' do
      fd2.update(role: fd1.role, version: 1)
      fd1.update(version: 2)
      expect(Hmis::Form::Definition.find_definition_for_role(fd1.role, project: p1)).to eq(fd1)
    end

    it 'should return the most recent version of a definition when a version is provided' do
      fd2.update(role: fd1.role, version: 1)
      fd1.update(version: 2)
      expect(Hmis::Form::Definition.find_definition_for_role(fd1.role, project: p1, version: 1)).to eq(fd2)
    end
  end

  describe 'with funder and project type instances' do
    let(:role) { :ENROLLMENT }
    it 'applies correct specificity (project > org > funder&ptype > funder > ptype)' do
      base_fd = Hmis::Form::Definition.find_definition_for_role(role) # created by hmis base setup

      p1 = create(:hmis_hud_project, project_type: 1)
      p2 = create(:hmis_hud_project, project_type: 1, funders: [43])
      p3 = create(:hmis_hud_project, project_type: 2, funders: [43])
      p4 = create(:hmis_hud_project, project_type: 2)
      p5 = create(:hmis_hud_project, project_type: 1, funders: [43])
      p6 = create(:hmis_hud_project, project_type: 1, funders: [43])

      fi1 = create(:hmis_form_instance, role: role, entity: nil, project_type: 1, funder: nil)
      fi2 = create(:hmis_form_instance, role: role, entity: nil, project_type: 1, funder: 43)
      fi3 = create(:hmis_form_instance, role: role, entity: nil, project_type: nil, funder: 43)
      fi4 = create(:hmis_form_instance, role: role, entity: p5)
      fi5 = create(:hmis_form_instance, role: role, entity: p6.organization)

      expect(Hmis::Form::Definition.find_definition_for_role(role, project: p1)).to eq(fi1.definition)
      expect(Hmis::Form::Definition.find_definition_for_role(role, project: p2)).to eq(fi2.definition)
      expect(Hmis::Form::Definition.find_definition_for_role(role, project: p3)).to eq(fi3.definition)
      expect(Hmis::Form::Definition.find_definition_for_role(role, project: p4)).to eq(base_fd)
      expect(Hmis::Form::Definition.find_definition_for_role(role, project: p5)).to eq(fi4.definition)
      expect(Hmis::Form::Definition.find_definition_for_role(role, project: p6)).to eq(fi5.definition)
    end
  end

  describe 'find_definition_for_service_type' do
    let(:role) { :SERVICE }
    it 'only service defintions for the specified service type are returned (regression test)' do
      cst1 = create(:hmis_custom_service_type, name: 'My service', data_source: ds1)
      p1 = create(:hmis_hud_project, project_type: 1)
      p2 = create(:hmis_hud_project, project_type: 1, funders: [43])
      p3 = create(:hmis_hud_project, project_type: 2)

      create(:hmis_form_instance, role: role, entity: nil, project_type: 1, funder: 43) # should never be chosen
      expect(Hmis::Form::Definition.find_definition_for_service_type(cst1, project: p1)).to be_nil

      # form by category
      fd1 = create(:hmis_form_definition, identifier: 'custom-service-def', role: role)
      create(:hmis_form_instance, role: role, definition: fd1, custom_service_category: cst1.category, entity: nil, project_type: nil, funder: nil)
      expect(Hmis::Form::Definition.find_definition_for_service_type(cst1, project: p1)).to eq(fd1)
      expect(Hmis::Form::Definition.find_definition_for_service_type(cst1, project: p2)).to eq(fd1)
      expect(Hmis::Form::Definition.find_definition_for_service_type(cst1, project: p3)).to eq(fd1)

      # form by type (more specific, so should be chosen over category form)
      fd2 = create(:hmis_form_definition, identifier: 'custom-service-def2', role: role)
      create(:hmis_form_instance, role: role, definition: fd2, custom_service_type: cst1, entity: nil, project_type: nil, funder: nil)
      expect(Hmis::Form::Definition.find_definition_for_service_type(cst1, project: p1)).to eq(fd2)
      expect(Hmis::Form::Definition.find_definition_for_service_type(cst1, project: p2)).to eq(fd2)
      expect(Hmis::Form::Definition.find_definition_for_service_type(cst1, project: p3)).to eq(fd2)
    end
  end

  describe 'deletion' do
    it 'should error if form has active instance' do
      expect(fd1.instances).to contain_exactly(fi1)

      # not allowed because this form might be actively in use
      expect { fd1.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end

    it 'should error if form has inactive instance' do
      fi1.update(active: false)
      expect(fd1.instances).to contain_exactly(fi1)

      # not allowed because historical data may use this form
      expect { fd1.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end

    # Note: Maybe in the future we want to support deleting old versions of FormDefinitions.
    # For now we restrict deleting the FormDefinition if there is ANY Form Instance referencing it via `identifier.`
    it 'should error if form has instances, even if there are newer versions of this form' do
      new_fd_version = fd1.dup
      new_fd_version.version = fd1.version + 1
      new_fd_version.save!

      # the form instance points to both form definitions, by identifier
      expect(fi1.definition_identifier).to eq(fd1.identifier)
      expect(fi1.definition_identifier).to eq(new_fd_version.identifier)

      # cant delete either form because the newer one is in use
      expect { new_fd_version.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
      expect { fd1.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end

    it 'should succeed if form has no instances' do
      fi1.delete
      expect(fd1.instances).to be_empty

      fd1.destroy!

      expect(fd1.deleted_at).to be_present
    end

    it 'should error if there are form processors linked to this form' do
      assessment = create(:hmis_custom_assessment, data_source: ds1, definition: fd1)
      expect(fd1.form_processors).to contain_exactly(assessment.form_processor)

      expect { fd1.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end
  end
end
