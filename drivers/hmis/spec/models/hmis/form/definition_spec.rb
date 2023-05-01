###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::Form::Definition, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:ds1) { create :hmis_data_source }
  let!(:user) { create(:user) }
  let(:hmis_user) { Hmis::User.find(user.id)&.tap { |u| u.update(hmis_data_source_id: ds1.id) } }
  let(:u1) { Hmis::Hud::User.from_user(hmis_user) }
  let(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }
  let!(:fd1) { create :hmis_form_definition, role: 'INTAKE' }
  let!(:fi1) { create :hmis_form_instance, definition: fd1, entity: p1 }
  let!(:no_permission_role) { create :role }
  let!(:empty_access_group) { create :access_group }

  before do
    empty_access_group.set_viewables({ data_sources: [ds1.id] })
    setup_acl(user, no_permission_role, empty_access_group)
  end

  it 'should return the right definition if a project has a specific assessment' do
    expect(Hmis::Form::Definition.find_definition_for_role(fd1.role, project: p1)).to eq(fd1)
  end

  it 'should return the right definition if a project\'s org has a specific assessment' do
    fi1.entity = o1
    fi1.save!
    expect(Hmis::Form::Definition.find_definition_for_role(fd1.role, project: p1)).to eq(fd1)
  end

  it 'should return the right definition if a project\'s type has a specific assessment' do
    fi1.update(entity_type: 'ProjectType', entity_id: p1.project_type)
    expect(Hmis::Form::Definition.find_definition_for_role(fd1.role, project: p1)).to eq(fd1)
  end

  it 'should return the right definition if a there\' only a default assessment' do
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
      fi2.update(entity_type: 'ProjectType', entity_id: p1.project_type)
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
end
