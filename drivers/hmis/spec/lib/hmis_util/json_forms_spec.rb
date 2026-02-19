# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisUtil::JsonForms do
  let(:json_forms) { described_class.new }
  let(:json_forms_with_qa_override) { described_class.new(env_key: 'qa_hmis') }
  let!(:data_source) { create(:hmis_data_source) }

  # Start with a clean slate
  before(:all) do
    Hmis::Form::Definition.delete_all
    Hmis::Form::Instance.delete_all
  end

  # Clean up any seeded forms between tests
  after(:each) do
    Hmis::Form::Definition.delete_all
    Hmis::Form::Instance.delete_all
  end

  # Reset forms to original state after all tests complete
  after(:all) do
    ::HmisUtil::JsonForms.seed_all
  end

  RSpec.shared_context 'a seeded form' do |role:, identifier: role.to_s.downcase|
    it "creates a published form definition for #{role}" do
      expect(Hmis::Form::Definition.where(role: role).count).to eq(1), "Expected 1 definition for role #{role}"
      definition = Hmis::Form::Definition.where(role: role).sole
      expect(definition.published?).to be(true), "Definition for #{identifier} is not published"
      expect(definition.managed_in_version_control).to be(true), "Definition for #{identifier} is not managed in version control"
      expect(definition.identifier).to eq(identifier), "Definition for #{identifier} has incorrect identifier"
      expect(definition.definition['item'].count).to be > 0, "Definition for #{identifier} has no items"
    end
  end

  RSpec.shared_context 'a default system form' do |role:, identifier: role.to_s.downcase|
    let(:instances) { Hmis::Form::Instance.where(definition_identifier: identifier) }

    it "creates a default system instance for #{role}" do
      expect(instances.size).to eq(1), "Expected 1 instance for identifier #{identifier}"
      instance = instances.sole
      expect(instance.system).to be(true), "Instance for #{identifier} is not a system instance"
      expect(instance.active).to be(true), "Instance for #{identifier} is not active"

      # Check for "default" which means there is no project/funder applicability
      expect(Hmis::Form::Instance.defaults.with_role(role)).to include(instance), "Instance for #{identifier} is not a default instance"
    end
  end

  describe '#seed_all' do
    describe 'in production environment' do
      before(:each) do
        allow(Rails.env).to receive(:production?).and_return(true)
        allow(Rails.env).to receive(:test?).and_return(false)
        allow(Rails.env).to receive(:development?).and_return(false)
      end

      describe 'read-only validations' do
        # could be optimized further, couldn't use before:all because of needing Rails.env mock
        before(:each) { described_class.seed_all }

        # Each system role (PROJECT, ORGANIZATION, CLIENT, etc.) should have exactly 1 form and 1 default system instance
        Hmis::Form::Definition::SYSTEM_FORM_ROLES.each do |role|
          it_behaves_like 'a seeded form', role: role
          it_behaves_like 'a default system form', role: role
        end

        # Each assessment role (INTAKE, EXIT, UPDATE, ANNUAL) should have exactly 1 form and 1 default system instance
        Hmis::Form::Definition::ASSESSMENT_FORM_ROLES.excluding(:CUSTOM_ASSESSMENT, :POST_EXIT).each do |role|
          it_behaves_like 'a seeded form', role: role, identifier: "base-#{role.to_s.downcase}"
          it_behaves_like 'a default system form', role: role, identifier: "base-#{role.to_s.downcase}"
        end

        # Each static role (FORM_RULE, PROJECT_CONFIG, etc.) should have exactly 1 form. Static forms do not have instances.
        Hmis::Form::Definition::STATIC_FORM_ROLES.each do |role|
          it_behaves_like 'a seeded form', role: role
        end

        # The HUD Service form (SERVICE) should have exactly 1 form. No instances, as those are loaded separately (HmisUtil::ServiceTypes.seed_hud_service_form_instances)
        it_behaves_like 'a seeded form', role: :SERVICE

        # The Current Living Situation form (CURRENT_LIVING_SITUATION) should have exactly 1 form and system rules for the default form
        it_behaves_like 'a seeded form', role: :CURRENT_LIVING_SITUATION
        it 'loads system instance rules for CURRENT_LIVING_SITUATION default form' do
          expected_specs = HudHelper.util.current_living_situation_funder_applicability_requirements
          rules = Hmis::Form::Instance.active.system.
            with_role(:CURRENT_LIVING_SITUATION).
            where(definition_identifier: 'current_living_situation')
          expect(rules.count).to eq(expected_specs.size)
          expect(rules).to all(be_system)
          actual_specs = rules.map { |r| r.slice(:project_type, :funder).compact_blank.symbolize_keys }.to_set
          expect(actual_specs).to eq(expected_specs.to_set)

          # should not create any non-system rules
          expect(Hmis::Form::Instance.not_system.with_role(:CURRENT_LIVING_SITUATION).count).to eq(0)
        end

        # Each HUD occurrence point form (Move-in Date, Date of Engagement, PATH Status) should have exactly 1 form and at least 1 system instance
        ['move_in_date', 'date_of_engagement', 'path_status'].each do |identifier|
          it "creates occurrence point form for #{identifier}" do
            scope = Hmis::Form::Definition.where(role: :OCCURRENCE_POINT, identifier: identifier)
            expect(scope.count).to eq(1)
            definition = scope.sole
            expect(definition.published?).to be(true)
            expect(definition.managed_in_version_control).to be(true)
            expect(definition.identifier).to eq(identifier)
          end

          it "creates system instance rules for #{identifier}" do
            rules = Hmis::Form::Instance.system.active.where(definition_identifier: identifier)
            expect(rules.count).to be >= 1
          end
        end
      end

      it 'does not create duplicates when run multiple times' do
        expect { described_class.seed_all }.to change(Hmis::Form::Definition, :count).and change(Hmis::Form::Instance, :count)
        expect { described_class.seed_all }.to not_change(Hmis::Form::Definition, :count).and not_change(Hmis::Form::Instance, :count)
      end

      it 'updates existing forms when definitions change' do
        described_class.seed_all

        # Get a form and modify its definition in memory
        client_form = Hmis::Form::Definition.find_by(identifier: 'client', role: :CLIENT)
        original_definition = client_form.definition.deep_dup

        # Simulate a change by modifying the definition
        modified_definition = original_definition.deep_dup
        modified_definition['item'] ||= []
        modified_definition['item'] << {
          'link_id' => 'test_field',
          'type' => 'STRING',
          'text' => 'Test Field Added',
        }

        # Manually update the database to simulate a file change
        client_form.update!(definition: modified_definition)
        client_form.reload

        # Verify the change was made
        expect(client_form.definition['item'].any? { |item| item['link_id'] == 'test_field' }).to be true

        # Run seed_all again - it should revert to the original definition
        expect { described_class.seed_all }.to not_change(Hmis::Form::Definition, :count).and not_change(Hmis::Form::Instance, :count)

        client_form.reload
        expect(client_form.definition['item'].none? { |item| item['link_id'] == 'test_field' }).to be true
      end
    end

    it 'loads test environment forms in test environment' do
      allow(Rails.env).to receive(:test?).and_return(true)

      expect do
        described_class.seed_all
      end.to change(Hmis::Form::Definition.where(role: :CUSTOM_ASSESSMENT, identifier: 'cls_assessment'), :count).from(0).to(1)
    end

    it 'does not load test environment forms in non-test environment' do
      allow(ENV).to receive(:[]).with('CLIENT').and_return('qa_hmis')
      allow(Rails.env).to receive(:test?).and_return(false)

      expect do
        described_class.seed_all
      end.to not_change(Hmis::Form::Definition.where(role: :CUSTOM_ASSESSMENT, identifier: 'cls_assessment'), :count).from(0)
    end
  end

  describe 'ENV CLIENT variable' do
    before(:each) do
      allow(ENV).to receive(:[]).with('CLIENT').and_return('allegheny')
      allow(Rails.env).to receive(:test?).and_return(false)
    end
    it 'uses ENV CLIENT when set' do
      json_forms = described_class.new
      expect(json_forms.send(:env_key)).to eq('allegheny')
    end

    it 'loads client-specific form definitions' do
      expect do
        described_class.seed_all
      end.to change(Hmis::Form::Definition.where(role: :CE_REFERRAL_STEP, identifier: 'change_provider_outcome'), :count)
    end
    it 'applies client-specific patches to form definitions' do
      described_class.seed_all

      client_form = Hmis::Form::Definition.managed_in_version_control.where(role: :CLIENT).sole
      expect(client_form).to be_present
      expect(client_form.definition.to_json).to include('mci_clearance')
    end
  end

  describe 'fragment resolution' do
    it 'resolves fragments in form definitions (smoke-test)' do
      json_forms.seed_all

      # Find a form that uses fragments (like intake assessment)
      intake_form = Hmis::Form::Definition.where(identifier: 'base-intake', role: :INTAKE).sole
      expect(intake_form).to be_present

      # The definition should not contain fragment references after loading
      definition_json = intake_form.definition.to_json
      expect(definition_json).not_to include('"fragment"')
    end
  end
end
