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
    Hmis::Form::Definition.delete_all
    Hmis::Form::Instance.delete_all
  end
  after(:all) do
    cleanup_test_environment
  end

  let(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, project_type: 7 }

  describe 'finding the definition for a HUD Assessment' do
    let(:role) { :INTAKE }
    # Intake for p1
    let!(:p1_intake_published) { create :hmis_form_definition, identifier: 'p1-intake', role: role, version: 3, status: :published }
    let!(:p1_intake_retired) { create :hmis_form_definition, identifier: 'p1-intake', role: role, version: 2, status: :retired } # cruft: old version
    let!(:p1_intake_rule) { create :hmis_form_instance, definition_identifier: 'p1-intake', entity: p1, active: true }

    # Intake for all projects
    let!(:default_intake_published) { create :hmis_form_definition, identifier: 'default-intake', role: role, version: 4, status: :published }
    let!(:default_intake_retired) { create :hmis_form_definition, identifier: 'default-intake', role: role, version: 3, status: :draft } # cruft: old version
    let!(:default_intake_rule) { create :hmis_form_instance, definition_identifier: 'default-intake', entity: nil, active: true }

    # cruft: form has active rules but only has a draft version
    let!(:draft_only_intake) { create :hmis_form_definition, identifier: 'draft-only-intake', role: role, version: 6, status: :draft }
    let!(:draft_only_intake_rule) { create :hmis_form_instance, definition_identifier: 'draft-only-intake', entity: p1, active: true }

    # cruft: form only has inactive rules
    let!(:inactive_intake) { create :hmis_form_definition, identifier: 'inactive-intake', role: role, version: 7, status: :published }
    let!(:inactive_intake_rule) { create :hmis_form_instance, definition_identifier: 'inactive-intake', entity: p1, active: false }

    def expect_definition(expected_fd, project: nil)
      selected = Hmis::Form::Definition.find_definition_for_role(role, project: project)

      # compare on a subset of attributes to make debugging easier
      comparison_attrs = [:id, :identifier, :version, :status]
      expect(selected.slice(*comparison_attrs)).to match(expected_fd.slice(*comparison_attrs))
    end

    it 'should use the definition with the most applicable rule' do
      expect_definition(p1_intake_published, project: p1) # uses p1_intake_rule
      expect_definition(default_intake_published, project: p2) # uses default_intake_rule
    end

    it 'should only return default-rule-definitions if project is not passed' do
      expect_definition(default_intake_published)
    end

    it 'should ignore inactive rules, even if they are more specific' do
      create(:hmis_form_instance, definition_identifier: 'p1-intake', entity: p2, active: false)
      # chooses default-intake based on default rule, even though p1-intake has a more specific rule that is inactive
      expect_definition(default_intake_published, project: p2)
    end

    it 'should use the definition with the most applicable rule (org rule)' do
      p1_intake_rule.update!(entity: o1)
      expect_definition(p1_intake_published, project: p1) # p1 belongs to o1
      expect_definition(p1_intake_published, project: p2) # p1 belongs to o2
    end

    it 'should use the definition with the most applicable rule (project type rule)' do
      p1_intake_rule.update!(entity: nil, project_type: p1.project_type)
      expect_definition(p1_intake_published, project: p1) # p1 intake matches project type
      expect_definition(default_intake_published, project: p2) # p1 intake does not match project type, fall back to default
    end

    it 'should prefer non-system rule over system rule when choosing a default instance' do
      default_intake_rule.update!(system: true)

      other_default_intake = create(:hmis_form_definition, identifier: 'custom-default-intake', role: role, version: 4, status: :published)
      other_default_rule = create(:hmis_form_instance, definition: other_default_intake, entity: nil, active: true, system: false)
      expect_definition(other_default_intake, project: p2) # chooses definition referenced by non-system rule
      expect_definition(other_default_intake) # same if project is not passed

      # test the other direction
      default_intake_rule.update!(system: false)
      other_default_rule.update!(system: true)
      expect_definition(default_intake_published, project: p2) # chooses definition referenced by non-system rule
      expect_definition(default_intake_published) # same if project is not passed
    end
  end

  describe 'finding the definition for an Enrollment form, with funder and project type instances' do
    it 'applies correct specificity (project > org > funder&ptype > funder > ptype)' do
      p1 = create(:hmis_hud_project, project_type: 1)
      p2 = create(:hmis_hud_project, project_type: 1, funders: [43])
      p3 = create(:hmis_hud_project, project_type: 2, funders: [43])
      p4 = create(:hmis_hud_project, project_type: 2) # matches default rule
      p5 = create(:hmis_hud_project, project_type: 1, funders: [43])
      p6 = create(:hmis_hud_project, project_type: 1, funders: [43])

      role = :CURRENT_LIVING_SITUATION
      fi1 = create(:hmis_form_instance, role: role, entity: nil, project_type: 1, funder: nil)
      fi2 = create(:hmis_form_instance, role: role, entity: nil, project_type: 1, funder: 43)
      fi3 = create(:hmis_form_instance, role: role, entity: nil, project_type: nil, funder: 43)
      fi4 = create(:hmis_form_instance, role: role, entity: p5)
      fi5 = create(:hmis_form_instance, role: role, entity: p6.organization)
      fi6 = create(:hmis_form_instance, role: role, entity: nil) # default rule

      expect(Hmis::Form::Definition.find_definition_for_role(role, project: p1)).to eq(fi1.definition)
      expect(Hmis::Form::Definition.find_definition_for_role(role, project: p2)).to eq(fi2.definition)
      expect(Hmis::Form::Definition.find_definition_for_role(role, project: p3)).to eq(fi3.definition)
      expect(Hmis::Form::Definition.find_definition_for_role(role, project: p4)).to eq(fi6.definition)
      expect(Hmis::Form::Definition.find_definition_for_role(role, project: p5)).to eq(fi4.definition)
      expect(Hmis::Form::Definition.find_definition_for_role(role, project: p6)).to eq(fi5.definition)
    end
  end

  describe 'the latest_versions scope' do
    # id1 has 2 retired, 1 published, and 1 draft version
    let!(:id1_retired1) { create :hmis_form_definition, identifier: 'identifier_1', version: 0, status: 'retired' }
    let!(:id1_retired2) { create :hmis_form_definition, identifier: 'identifier_1', version: 1, status: 'retired' }
    let!(:id1_published) { create :hmis_form_definition, identifier: 'identifier_1', version: 2, status: 'published' }
    let!(:id1_draft) { create :hmis_form_definition, identifier: 'identifier_1', version: 3, status: 'draft' }

    # id2 exists only in draft
    let!(:id2_draft) { create :hmis_form_definition, identifier: 'identifier_2', version: 0, status: 'draft' }

    # id3 has 2 retired versions, no currently published or draft versions
    let!(:id3_retired1) { create :hmis_form_definition, identifier: 'identifier_3', version: 0, status: 'retired' }
    let!(:id3_retired2) { create :hmis_form_definition, identifier: 'identifier_3', version: 1, status: 'retired' }

    it 'should have correct relationships when there are multiple retired, 1 published, and 1 draft' do
      latest = Hmis::Form::Definition.where(identifier: 'identifier_1').latest_versions
      expect(latest.size).to eq(1)
      expect(latest.first).to eq(id1_draft)

      expect(id1_retired1.published_version).to eq(id1_published)
      expect(id1_retired1.draft_version).to eq(id1_draft)
      expect(id1_draft.published_version).to eq(id1_published)
    end

    it 'should have no relationships when there is only 1 draft' do
      latest = Hmis::Form::Definition.where(identifier: 'identifier_2').latest_versions
      expect(latest.size).to eq(1)
      expect(latest.first).to eq(id2_draft)

      expect(id2_draft.published_version).to be_nil
      expect(id2_draft.all_versions.size).to eq(1)
    end

    it 'should have correct relationships when there are no published or draft' do
      latest = Hmis::Form::Definition.where(identifier: 'identifier_3').latest_versions
      expect(latest.size).to eq(1)
      expect(latest.first).to eq(id3_retired2)

      expect(id3_retired2.draft_version).to be_nil
      expect(id3_retired2.published_version).to be_nil
      expect(id3_retired2.all_versions.size).to eq(2)
    end

    it 'should return one version per identifier' do
      def_scope = Hmis::Form::Definition.where(identifier: ['identifier_1', 'identifier_2', 'identifier_3'])
      latest = def_scope.latest_versions
      expect(latest).to contain_exactly(id1_draft, id2_draft, id3_retired2)

      drafts = def_scope.draft
      expect(drafts).to contain_exactly(id1_draft, id2_draft)

      published = def_scope.published
      expect(published).to contain_exactly(id1_published)

      retired = def_scope.retired
      expect(retired).to contain_exactly(id1_retired1, id1_retired2, id3_retired1, id3_retired2)
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
    let!(:fd1) { create :hmis_form_definition, identifier: 'p1-intake', role: :INTAKE, version: 3, status: :published }
    let!(:fi1) { create :hmis_form_instance, definition: fd1, entity: p1, active: true }

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
      fd1.status = Hmis::Form::Definition::RETIRED
      fd1.save!
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
