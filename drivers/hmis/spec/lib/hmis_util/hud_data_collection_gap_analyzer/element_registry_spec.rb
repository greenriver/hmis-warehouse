###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisUtil::HudDataCollectionGapAnalyzer::ElementRegistry do
  subject(:registry) { described_class.new }

  let(:elements) { registry.assessment_elements }

  it 'resolves fragments to reach items that the base assessment files only reference' do
    # base_intake.json itself declares only ENROLLMENT mappings; income items live in
    # the income_and_sources fragment, so finding one proves fragments were resolved.
    intake_income = elements.select { |e| e.role == :INTAKE && e.record_type == 'INCOME_BENEFIT' }
    intake_enrollment = elements.select { |e| e.role == :INTAKE && e.record_type == 'ENROLLMENT' }

    expect(intake_income.map(&:field_name)).to include('incomeFromAnySource')
    expect(intake_enrollment.map(&:field_name)).to include('livingSituation')
  end

  it 'emits only the target record types' do
    expect(elements.map(&:record_type).uniq).to match_array(
      ['INCOME_BENEFIT', 'DISABILITY_GROUP', 'HEALTH_AND_DV', 'EMPLOYMENT_EDUCATION', 'YOUTH_EDUCATION_STATUS', 'ENROLLMENT', 'EXIT'],
    )
  end

  it 'excludes DISPLAY items, which carry no stored data' do
    expect(elements.map(&:item_type)).not_to include('DISPLAY')
  end

  it 'maps a disability response field to its DisabilityType and response column' do
    element = elements.find { |e| e.field_name == 'physicalDisabilityIndefiniteAndImpairs' }

    expect(element).to have_attributes(
      disability_type: 5,
      column: :IndefiniteAndImpairs,
      association_name: :disabilities,
    )
  end

  it 'maps a HOPWA disability field to DisabilityType 8 and its own column' do
    element = elements.find { |e| e.field_name == 'viralLoad' }

    expect(element).to have_attributes(disability_type: 8, column: :ViralLoad)
  end

  it 'maps an enrollment acronym field and a multi-select exit field to HUD columns' do
    expect(elements.find { |e| e.field_name == 'dateToStreetEssh' }.column).to eq(:DateToStreetESSH)
    expect(elements.find { |e| e.field_name == 'counselingMethods' }.column).to eq(:IndividualCounseling)
    expect(elements.find { |e| e.field_name == 'aftercareMethods' }.column).to eq(:Telephone)
  end

  describe '#definition_tree' do
    def find_item(node, link_id)
      return node if node['link_id'] == link_id

      node['item']&.each do |child|
        found = find_item(child, link_id)
        return found if found
      end
      nil
    end

    it 'annotates a group link id with the HUD rule that governs its children' do
      # HUD rules key on group link ids, not the leaf items carrying field names.
      group = find_item(registry.definition_tree(:INTAKE), 'income_and_sources')

      expect(group['rule']).to include('operator' => 'ANY')
    end

    it 'leaves leaf items unannotated, since requiredness is inherited from their group' do
      leaf = find_item(registry.definition_tree(:INTAKE), 'q_4_05_2')

      expect(leaf['rule']).to be_nil
    end

    it 'returns an independent copy each call, so filtering one does not corrupt the next' do
      # DefinitionItemFilter empties item['item'] on nested nodes, not just the root, so a
      # copy that shares its children would hand the next caller a pruned tree.
      first = registry.definition_tree(:INTAKE)
      find_item(first, 'income_and_sources')['item'] = []

      expect(find_item(registry.definition_tree(:INTAKE), 'income_and_sources')['item']).to be_present
    end
  end

  it 'resolves every element to a column that exists on its target model' do
    offenders = elements.reject do |element|
      element.model_name.constantize.column_names.include?(element.column.to_s)
    end

    expect(offenders.map(&:field_name)).to be_empty
  end
end
