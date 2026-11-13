###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'ostruct'
require 'rails_helper'

RSpec.describe Hmis::Filter::FormDefinitionFilter, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  # Mirrors the scope used by the formIdentifiers query: one row per identifier, the latest version.
  # Limited to the identifiers built by each example group, since the test database may hold
  # JSON-seeded form definitions from other suites.
  let(:base_scope) { Hmis::Form::Definition.where(data_source_id: data_source.id, identifier: identifiers).latest_versions }

  def filtered_identifiers(**filters)
    described_class.new(OpenStruct.new(**filters)).filter_scope(base_scope).map(&:identifier)
  end

  describe 'form type filter' do
    let(:identifiers) { ['update_form', 'service_form', 'case_note_form'] }
    let!(:update_form) { create(:hmis_form_definition, data_source: data_source, identifier: 'update_form', role: :UPDATE) }
    let!(:service_form) { create(:hmis_form_definition, data_source: data_source, identifier: 'service_form', role: :SERVICE) }
    let!(:case_note_form) { create(:hmis_form_definition, data_source: data_source, identifier: 'case_note_form', role: :CASE_NOTE) }

    it 'filters to one form type' do
      expect(filtered_identifiers(form_type: ['SERVICE'])).to contain_exactly(service_form.identifier)
    end

    it 'returns the union of multiple form types' do
      expect(filtered_identifiers(form_type: ['SERVICE', 'CASE_NOTE'])).to contain_exactly(service_form.identifier, case_note_form.identifier)
    end

    it 'returns no rows when no form has the selected type' do
      expect(filtered_identifiers(form_type: ['CURRENT_LIVING_SITUATION'])).to be_empty
    end

    it 'leaves the scope unchanged when unset' do
      expect(filtered_identifiers(form_type: nil)).to contain_exactly(update_form.identifier, service_form.identifier, case_note_form.identifier)
      expect(filtered_identifiers(form_type: [])).to contain_exactly(update_form.identifier, service_form.identifier, case_note_form.identifier)
    end
  end

  describe 'combined filters' do
    let(:identifiers) { ['service_intake', 'service_exit', 'update_intake'] }
    let!(:service_intake) { create(:hmis_form_definition, data_source: data_source, identifier: 'service_intake', role: :SERVICE, title: 'Service Intake') }
    let!(:service_exit) { create(:hmis_form_definition, data_source: data_source, identifier: 'service_exit', role: :SERVICE, title: 'Service Exit') }
    let!(:update_intake) { create(:hmis_form_definition, data_source: data_source, identifier: 'update_intake', role: :UPDATE, title: 'Update Intake') }

    it 'requires both form type and search term to match' do
      expect(filtered_identifiers(form_type: ['SERVICE'], search_term: 'Intake')).to contain_exactly('service_intake')
    end
  end

  describe 'search term filter' do
    let(:identifiers) { ['client_intake', 'bed_night'] }
    let!(:intake_form) { create(:hmis_form_definition, data_source: data_source, identifier: 'client_intake', title: 'Client Intake') }
    let!(:other_form) { create(:hmis_form_definition, data_source: data_source, identifier: 'bed_night', title: 'Bed Night') }

    it 'matches on title' do
      expect(filtered_identifiers(search_term: 'Client Int')).to contain_exactly(intake_form.identifier)
    end

    it 'matches on identifier' do
      expect(filtered_identifiers(search_term: 'bed_night')).to contain_exactly(other_form.identifier)
    end
  end
end
