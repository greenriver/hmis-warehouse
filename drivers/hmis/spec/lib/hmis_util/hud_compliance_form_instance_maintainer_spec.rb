# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisUtil::HudComplianceFormInstanceMaintainer do
  include_context 'hmis json forms seed'
  let!(:data_source) { ds1 }

  def maintainer(**opts)
    described_class.new(data_source_id: data_source.id, **opts)
  end

  describe '#ensure_all_system_instances_exist!' do
    it 'is idempotent' do
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
      count_after_deletion = Hmis::Form::Instance.count

      maintainer.ensure_all_system_instances_exist!

      expect(Hmis::Form::Instance.count).to eq(count_after_deletion + deleted_count)
      expect(Hmis::Form::Instance.system.where(definition_identifier: 'client')).to exist
      expect(Hmis::Form::Instance.system.where(definition_identifier: 'project')).to exist
    end

    it 'recreates missing assessment instances' do
      Hmis::Form::Instance.system.where(definition_identifier: 'base-intake').delete_all
      Hmis::Form::Instance.system.where(definition_identifier: 'base-exit').delete_all
      count_before = Hmis::Form::Instance.count

      maintainer.ensure_all_system_instances_exist!

      expect(Hmis::Form::Instance.count).to eq(count_before + 2)
      expect(Hmis::Form::Instance.system.where(definition_identifier: 'base-intake')).to exist
      expect(Hmis::Form::Instance.system.where(definition_identifier: 'base-exit')).to exist
    end

    it 'updates existing rule from active: false to active: true and system: true without creating a duplicate' do
      client_instance = Hmis::Form::Instance.defaults.find_by(definition_identifier: 'client')
      client_instance.update!(active: false, system: false)

      expect do
        maintainer.ensure_all_system_instances_exist!
        client_instance.reload
      end.to change(client_instance, :active).from(false).to(true).
        and change(client_instance, :system).from(false).to(true).
        and not_change(Hmis::Form::Instance, :count)
    end

    it 'creates system instances for CLS that match HudHelper.util.current_living_situation_funder_applicability_requirements' do
      Hmis::Form::Instance.system.where(definition_identifier: 'current_living_situation').delete_all
      expected_specs = HudHelper.util.current_living_situation_funder_applicability_requirements

      maintainer.ensure_all_system_instances_exist!

      rules = Hmis::Form::Instance.active.system.
        where(definition_identifier: 'current_living_situation')
      expect(rules.count).to eq(expected_specs.size)
      actual_specs = rules.map { |r| { project_type: r.project_type, funder: r.funder }.compact_blank }.to_set
      expect(actual_specs).to eq(expected_specs.to_set)
    end

    it 'creates system instances for service form that match HudHelper.util.service_form_funder_applicability_requirements per data source' do
      HmisUtil::ServiceTypes.seed_hud_service_types(data_source.id)
      Hmis::Form::Instance.system.where(definition_identifier: 'service').delete_all

      requirements = HudHelper.util.service_form_funder_applicability_requirements
      expected_specs = Set.new
      requirements.each do |config|
        category = Hmis::Hud::CustomServiceType.where(
          data_source_id: data_source.id,
          hud_record_type: config[:record_type],
        ).first&.custom_service_category
        raise "missing CustomServiceCategory for record_type #{config[:record_type]} in DS##{data_source.id}" unless category

        config[:applicability_requirements].each do |requirement|
          expected_specs << {
            custom_service_category_id: category.id,
            data_collected_about: config[:data_collected_about].to_s,
            project_type: requirement[:project_type],
            funder: requirement[:funder],
          }
        end
      end

      maintainer.ensure_all_system_instances_exist!

      rules = Hmis::Form::Instance.active.system.where(definition_identifier: 'service')
      expect(rules.count).to eq(expected_specs.size)
      actual_specs = rules.map do |r|
        {
          custom_service_category_id: r.custom_service_category_id,
          data_collected_about: r.data_collected_about.to_s,
          project_type: r.project_type,
          funder: r.funder,
        }
      end.to_set
      expect(actual_specs).to eq(expected_specs)
    end

    context 'with dry run' do
      it 'does not create records when instances are missing, but logs them in the summary' do
        # Delete some system instances so there are missing compliance instances
        Hmis::Form::Instance.system.where(definition_identifier: 'client').delete_all
        Hmis::Form::Instance.system.where(definition_identifier: 'project').delete_all
        Hmis::Form::Instance.system.where(definition_identifier: 'move_in_date').last.update!(system: false) # should trigger update
        count_after_deletion = Hmis::Form::Instance.count

        allow(Rails.logger).to receive(:info)
        maintainer(dry_run: true).ensure_all_system_instances_exist!

        expect(Rails.logger).to have_received(:info).with(
          a_string_including('HUD Form Compliance (dry run)', 'Would create (2):', 'client', 'project', 'Would update (1):', 'move_in_date'),
        )
        expect(Hmis::Form::Instance.count).to eq(count_after_deletion)
      end
    end
  end
end
