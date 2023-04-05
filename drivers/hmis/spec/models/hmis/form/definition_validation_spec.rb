###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Form::Definition, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  HUD_ASSESSMENT_ROLES = [:INTAKE, :UPDATE, :ANNUAL, :EXIT].freeze

  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: 2.weeks.ago }
  let!(:exit2) { create :hmis_hud_exit, enrollment: e2, data_source: ds1, client: c1, user: u1, exit_date: 1.week.ago }

  let(:default_args) do
    {
      enrollment: e2,
      ignore_warnings: true,
    }
  end

  describe 'Validating assessment date on HUD assessments' do
    it 'should error if assessment date value is missing from hud_values' do
      HUD_ASSESSMENT_ROLES.each do |role|
        definition = Hmis::Form::Definition.find_by(role: role)
        date, errors = definition.find_and_validate_assessment_date(values: { 'foo': 'bar' }, **default_args)
        expect(date).to be_nil
        expect(errors.length).to eq(1)
        expect(errors[0].type).to eq(:required)
        expect(errors[0].attribute).to eq(definition.assessment_date_item.field_name.to_sym)
      end
    end

    it 'should error if assessment date value is null in hud_values' do
      HUD_ASSESSMENT_ROLES.each do |role|
        definition = Hmis::Form::Definition.find_by(role: role)
        link_id = definition.assessment_date_item.link_id
        date, errors = definition.find_and_validate_assessment_date(values: { link_id => nil }, **default_args)
        expect(date).to be_nil
        expect(errors.length).to eq(1)
        expect(errors[0].type).to eq(:required)
        expect(errors[0].attribute).to eq(definition.assessment_date_item.field_name.to_sym)
      end
    end

    HUD_ASSESSMENT_ROLES.each do |role|
      it "should succeed if assessment date is the same as entry date (#{role})" do
        definition = Hmis::Form::Definition.find_by(role: role)
        link_id = definition.assessment_date_item.link_id
        assessment_date = e2.entry_date.strftime('%Y-%m-%d')

        date, errors = definition.find_and_validate_assessment_date(values: { link_id => assessment_date }, **default_args)
        expect(errors).to be_empty
        expect(date).to eq(e2.entry_date)
      end
    end

    HUD_ASSESSMENT_ROLES.excluding(:INTAKE).each do |role|
      it "should error if assessment date is before entry date (#{role})" do
        definition = Hmis::Form::Definition.find_by(role: role)
        link_id = definition.assessment_date_item.link_id
        assessment_date = (e2.entry_date - 1.day).strftime('%Y-%m-%d')

        date, errors = definition.find_and_validate_assessment_date(values: { link_id => assessment_date }, **default_args)
        expect(errors.length).to eq(1)
        expect(errors[0].type).to eq(:out_of_range)
        expect(errors[0].attribute).to eq(definition.assessment_date_item.field_name.to_sym)
        expect(date).to be_nil
      end
    end

    it 'should succeed if assessment date is before entry date (intake)' do
      definition = Hmis::Form::Definition.find_by(role: :INTAKE)
      link_id = definition.assessment_date_item.link_id
      assessment_date = (e2.entry_date - 1.day).strftime('%Y-%m-%d')

      date, errors = definition.find_and_validate_assessment_date(values: { link_id => assessment_date }, **default_args)
      expect(date).to eq(e2.entry_date - 1.day)
      expect(errors).to be_empty
    end

    HUD_ASSESSMENT_ROLES.excluding(:EXIT).each do |role|
      it "should error if assessment date is after exit date (#{role})" do
        definition = Hmis::Form::Definition.find_by(role: role)
        link_id = definition.assessment_date_item.link_id
        e2.exit.update(exit_date: 3.days.ago)
        assessment_date = (e2.exit_date + 1.day).strftime('%Y-%m-%d')

        date, errors = definition.find_and_validate_assessment_date(values: { link_id => assessment_date }, **default_args)
        expect(date).to be_nil
        expect(errors.length).to eq(1)
        expect(errors[0].type).to eq(:out_of_range)
        expect(errors[0].attribute).to eq(definition.assessment_date_item.field_name.to_sym)
      end
    end

    it 'should succeed if assessment date is after exit date (exit)' do
      definition = Hmis::Form::Definition.find_by(role: :EXIT)
      link_id = definition.assessment_date_item.link_id
      e2.exit.update(exit_date: 3.days.ago)
      assessment_date = (e2.exit_date + 1.day).strftime('%Y-%m-%d')

      date, errors = definition.find_and_validate_assessment_date(values: { link_id => assessment_date }, **default_args)
      expect(date).to eq(e2.exit_date + 1.day)
      expect(errors).to be_empty
    end

    it 'should error if date is invalid/malformed' do
      ['2020', '2020-18-32'].each do |malformed_date|
        definition = Hmis::Form::Definition.find_by(role: :ANNUAL)
        link_id = definition.assessment_date_item.link_id
        date, errors = definition.find_and_validate_assessment_date(values: { link_id => malformed_date }, **default_args)

        expect(date).to be_nil
        expect(errors.length).to eq(1)
        expect(errors[0].type).to eq(:invalid)
        expect(errors[0].attribute).to eq(definition.assessment_date_item.field_name.to_sym)
      end
    end

    it 'should error if date is >20 years ago' do
      ['0020-01-01', '1980-01-01'].each do |malformed_date|
        definition = Hmis::Form::Definition.find_by(role: :ANNUAL)
        link_id = definition.assessment_date_item.link_id
        date, errors = definition.find_and_validate_assessment_date(values: { link_id => malformed_date }, **default_args)

        expect(date).to be_nil
        expect(errors.length).to eq(2)
        expect(errors[0].type).to eq(:out_of_range)
        expect(errors[0].attribute).to eq(definition.assessment_date_item.field_name.to_sym)
      end
    end
  end

  describe 'Validating form values on HUD assessments' do
    let(:completed_values_for_update) do
      {
        "information-date-input": '2023-02-15',
        "3.16": 'SC-501',
        "4.02.2": 'CLIENT_REFUSED',
        "4.03.2": 'YES',
        "4.03.3": nil,
        "4.03.4": nil,
        "4.03.5": nil,
        "4.03.6": nil,
        "4.03.7": nil,
        "4.03.8": true,
        "4.03.A": 'other description', # required field when enabled
        "4.04.2": 'NO',
        "4.05.2": 'NO',
        "4.06.2": 'NO',
        "4.07.2": 'NO',
        "4.08.2": 'NO',
        "4.09.2": 'NO',
        "4.10.2": 'NO',
        "3.08": 'CLIENT_REFUSED',
        "4.11.2": 'NO',
      }
    end
    # It doesn't matter what the raw values are set to, but all the keys need to be present
    let(:empty_values_for_update) { completed_values_for_update.keys.map { |k| [k, nil] }.to_h }

    it 'should have no errors when Update assessment is completely filled in' do
      definition = Hmis::Form::Definition.find_by(role: :UPDATE)
      errors = definition.validate_form_values(completed_values_for_update.stringify_keys)
      expect(errors).to be_empty
    end

    it 'should return warnings for warn_if_empty items' do
      definition = Hmis::Form::Definition.find_by(role: :UPDATE)
      values = {
        **completed_values_for_update,
        "4.11.2": 'YES',
        "4.11.A": nil,
        "4.11.B": nil,
      }
      expected_errors = [
        {
          type: :data_not_collected,
          severity: :warning,
          readable_attribute: 'When DV Occurred',
          link_id: '4.11.A',
        },
        {
          type: :data_not_collected,
          severity: :warning,
          readable_attribute: 'Currently Fleeing DV',
          link_id: '4.11.B',
        },
      ]

      errors = definition.validate_form_values(values.stringify_keys)
      expect(errors.map(&:to_h)).to match(expected_errors.map { |h| a_hash_including(**h) })
    end

    it 'should warn if conditional warn_if_empty field is enabled' do
      definition = Hmis::Form::Definition.find_by(role: :UPDATE)
      values = {
        **completed_values_for_update,
        "4.03.A": nil,
      }
      expected_errors = [
        {
          type: :data_not_collected,
          severity: :warning,
          readable_attribute: 'Other benefits source',
        },
      ]

      errors = definition.validate_form_values(values.stringify_keys)
      expect(errors.map(&:to_h)).to match(expected_errors.map { |h| a_hash_including(**h) })
    end
  end

  describe 'Validating mock form validation' do
    # Test using factory because actual forms don't have any required fields aside from assessment date
    let!(:factory_form_definition) { create :hmis_form_definition }
    it 'should error if required field is nil' do
      values = { 'linkid-required': nil }
      expected_errors = [
        {
          type: :required,
          severity: :error,
          readable_attribute: 'The Required Field',
        },
      ]
      errors = factory_form_definition.validate_form_values(values.stringify_keys)
      expect(errors.map(&:to_h)).to match(expected_errors.map { |h| a_hash_including(**h) })
    end
  end
end
