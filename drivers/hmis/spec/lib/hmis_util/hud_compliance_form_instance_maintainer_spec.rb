# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisUtil::HudComplianceFormInstanceMaintainer do
  let!(:data_source) { create(:hmis_data_source) }

  before(:each) do
    described_class.new.ensure_all_system_instances_exist!
  end

  after(:all) do
    # clear and reset to original state
    Hmis::Form::Instance.delete_all
    HmisUtil::JsonForms.seed_all
  end

  describe '#ensure_all_system_instances_exist!' do
    it 'is idempotent' do
      maintainer = described_class.new
      initial_count = Hmis::Form::Instance.count

      maintainer.ensure_all_system_instances_exist!
      maintainer.ensure_all_system_instances_exist!

      expect(Hmis::Form::Instance.count).to eq(initial_count)
    end

    it 'recreates missing record form instances' do
      # Delete some system instances (e.g. default system form instances)
      Hmis::Form::Instance.system.where(definition_identifier: 'client').delete_all
      Hmis::Form::Instance.system.where(definition_identifier: 'project').delete_all
      deleted_count = 2
      count_before = Hmis::Form::Instance.count

      described_class.new.ensure_all_system_instances_exist!

      expect(Hmis::Form::Instance.count).to eq(count_before + deleted_count)
      expect(Hmis::Form::Instance.system.where(definition_identifier: 'client')).to exist
      expect(Hmis::Form::Instance.system.where(definition_identifier: 'project')).to exist
    end

    it 'recreates missing assessment instances' do
      Hmis::Form::Instance.system.where(definition_identifier: 'base-intake').delete_all
      Hmis::Form::Instance.system.where(definition_identifier: 'base-exit').delete_all
      count_before = Hmis::Form::Instance.count

      described_class.new.ensure_all_system_instances_exist!

      expect(Hmis::Form::Instance.count).to eq(count_before + 2)
      expect(Hmis::Form::Instance.system.where(definition_identifier: 'base-intake')).to exist
      expect(Hmis::Form::Instance.system.where(definition_identifier: 'base-exit')).to exist
    end

    it 'updates existing rule from system: false to system: true without creating a duplicate' do
      client_instance = Hmis::Form::Instance.defaults.find_by(definition_identifier: 'client')
      client_instance.update!(system: false)

      expect do
        described_class.new.ensure_all_system_instances_exist!
        client_instance.reload
      end.to change(client_instance, :system).from(false).to(true).
        and not_change(Hmis::Form::Instance, :count)
    end

    it 'updates existing rule from active: false to active: true and system: true without creating a duplicate' do
      client_instance = Hmis::Form::Instance.defaults.find_by(definition_identifier: 'client')
      client_instance.update!(active: false, system: false)

      expect do
        described_class.new.ensure_all_system_instances_exist!
        client_instance.reload
      end.to change(client_instance, :active).from(false).to(true).
        and change(client_instance, :system).from(false).to(true).
        and not_change(Hmis::Form::Instance, :count)
    end

    it 'creates system instances for CLS that match HudHelper.util.current_living_situation_funder_applicability_requirements' do
      Hmis::Form::Instance.system.where(definition_identifier: 'current_living_situation').delete_all
      expected_specs = HudHelper.util.current_living_situation_funder_applicability_requirements

      described_class.new.ensure_all_system_instances_exist!

      rules = Hmis::Form::Instance.active.system.
        where(definition_identifier: 'current_living_situation')
      expect(rules.count).to eq(expected_specs.size)
      actual_specs = rules.map { |r| { project_type: r.project_type, funder: r.funder }.compact_blank }.to_set
      expect(actual_specs).to eq(expected_specs.to_set)
    end

    context 'with dry run' do
      it 'does not create records when instances are missing, but prints them in the summary' do
        # Delete some system instances so there are missing compliance instances
        Hmis::Form::Instance.system.where(definition_identifier: 'client').delete_all
        Hmis::Form::Instance.system.where(definition_identifier: 'project').delete_all
        count_after_deletion = Hmis::Form::Instance.count

        expect do
          described_class.new(dry_run: true).ensure_all_system_instances_exist!
        end.to output(a_string_including('HUD Form Compliance (dry run)', 'Record forms', 'new instances that would be created', 'Default (all projects): 2')).to_stdout

        expect(Hmis::Form::Instance.count).to eq(count_after_deletion)
      end
    end
  end
end
