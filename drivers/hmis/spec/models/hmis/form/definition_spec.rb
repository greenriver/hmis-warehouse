require 'rails_helper'

RSpec.describe Hmis::Form::Definition, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let(:user) { create :user }
  let(:ds1) { create :hmis_data_source }
  let(:o1) { create :hmis_hud_organization, data_source_id: ds1.id }
  let(:p1) { create :hmis_hud_project, data_source_id: ds1.id, OrganizationID: o1.OrganizationID }
  let(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:fd1) { create :hmis_form_definition }
  let!(:fi1) { create :hmis_form_instance, definition: fd1, entity: p1 }

  it 'should return the right definition if a project has a specific assessment' do
    expect(Hmis::Form::Definition.find_definition_for_project(p1, role: fd1.role)).to eq(fd1)
  end

  it 'should return the right definition if a project\'s org has a specific assessment' do
    fi1.entity = o1
    fi1.save!
    expect(Hmis::Form::Definition.find_definition_for_project(p1, role: fd1.role)).to eq(fd1)
  end

  it 'should return the right definition if a project\'s type has a specific assessment' do
    fi1.update(entity_type: 'ProjectType', entity_id: p1.project_type)
    expect(Hmis::Form::Definition.find_definition_for_project(p1, role: fd1.role)).to eq(fd1)
  end

  it 'should return the right definition if a there\' only a default assessment' do
    fi1.entity = nil
    fi1.save!
    expect(Hmis::Form::Definition.find_definition_for_project(p1, role: fd1.role)).to eq(fd1)
  end

  describe 'with multiple definitions' do
    let!(:fd2) { create :hmis_form_definition, role: 'UPDATE' }
    let!(:fi2) { create :hmis_form_instance, definition: fd2, entity: p1 }

    it 'should return a definition with the correct role' do
      expect(Hmis::Form::Definition.find_definition_for_project(p1, role: fd1.role)).to eq(fd1)
      expect(Hmis::Form::Definition.find_definition_for_project(p1, role: fd2.role)).to eq(fd2)
    end

    it 'should return the most specific definition with the correct role' do
      fi2.update(entity_type: 'ProjectType', entity_id: p1.project_type)
      fd2.update(role: fd1.role)
      expect(Hmis::Form::Definition.find_definition_for_project(p1, role: fd1.role)).to eq(fd1)
    end

    it 'should return the most recent version of a definition when no version provided' do
      fd2.update(role: fd1.role, version: 1)
      fd1.update(version: 2)
      expect(Hmis::Form::Definition.find_definition_for_project(p1, role: fd1.role)).to eq(fd1)
    end
    it 'should return the most recent version of a definition when a version is provided' do
      fd2.update(role: fd1.role, version: 1)
      fd1.update(version: 2)
      expect(Hmis::Form::Definition.find_definition_for_project(p1, role: fd1.role, version: 1)).to eq(fd2)
    end
  end
end
