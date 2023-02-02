require 'rails_helper'
require_relative 'hmis_form_setup'

RSpec.describe Hmis::Form::Definition, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis form setup'

  HUD_ASSESSMENT_ROLES = [:INTAKE, :UPDATE, :ANNUAL, :EXIT].freeze
  let(:entry_date) { Date.parse('2020-01-01') }
  let(:exit_date) { Date.parse('2024-01-01') }
  let(:default_args) { { entry_date: entry_date, exit_date: exit_date } }

  describe 'find and validate assessment' do
    it 'should error if assessment date value is missing from hud_values' do
      HUD_ASSESSMENT_ROLES.each do |role|
        definition = Hmis::Form::Definition.find_by(role: role)
        date, errors = definition.find_and_validate_assessment_date(hud_values: { 'foo': 'bar' }, **default_args)
        expect(date).to be_nil
        expect(errors.length).to eq(1)
        expect(errors[0].type).to eq(:required)
        expect(errors[0].attribute).to eq(definition.assessment_date_item.field_name)
      end
    end

    it 'should error if assessment date value is null in hud_values' do
      HUD_ASSESSMENT_ROLES.each do |role|
        definition = Hmis::Form::Definition.find_by(role: role)
        link_id = definition.assessment_date_item.link_id
        date, errors = definition.find_and_validate_assessment_date(hud_values: { link_id => nil }, **default_args)
        expect(date).to be_nil
        expect(errors.length).to eq(1)
        expect(errors[0].type).to eq(:required)
        expect(errors[0].attribute).to eq(definition.assessment_date_item.field_name)
      end
    end

    it 'should succeed if assessment date is the same as entry date for all roles' do
      HUD_ASSESSMENT_ROLES.each do |role|
        definition = Hmis::Form::Definition.find_by(role: role)
        link_id = definition.assessment_date_item.link_id
        assessment_date = entry_date.strftime('%Y-%m-%d')

        date, errors = definition.find_and_validate_assessment_date(hud_values: { link_id => assessment_date }, **default_args)
        expect(errors).to be_empty
        expect(date).to eq(entry_date)
      end
    end

    it 'should error if assessment date is before entry date (non-intake)' do
      HUD_ASSESSMENT_ROLES.excluding(:INTAKE).each do |role|
        definition = Hmis::Form::Definition.find_by(role: role)
        link_id = definition.assessment_date_item.link_id
        assessment_date = (entry_date - 1.day).strftime('%Y-%m-%d')

        date, errors = definition.find_and_validate_assessment_date(hud_values: { link_id => assessment_date }, **default_args)
        expect(errors.length).to eq(1)
        expect(errors[0].type).to eq(:out_of_range)
        expect(errors[0].attribute).to eq(definition.assessment_date_item.field_name)
        expect(date).to be_nil
      end
    end

    it 'should succeed if assessment date is before entry date (intake)' do
      definition = Hmis::Form::Definition.find_by(role: 'INTAKE')
      link_id = definition.assessment_date_item.link_id
      assessment_date = (entry_date - 1.day).strftime('%Y-%m-%d')

      date, errors = definition.find_and_validate_assessment_date(hud_values: { link_id => assessment_date }, **default_args)
      expect(date).to eq(entry_date - 1.day)
      expect(errors).to be_empty
    end

    it 'should error if assessment date is after exit date (non-exit)' do
      HUD_ASSESSMENT_ROLES.excluding(:EXIT).each do |role|
        definition = Hmis::Form::Definition.find_by(role: role)
        link_id = definition.assessment_date_item.link_id
        assessment_date = (exit_date + 1.day).strftime('%Y-%m-%d')

        date, errors = definition.find_and_validate_assessment_date(hud_values: { link_id => assessment_date }, **default_args)
        expect(date).to be_nil
        expect(errors.length).to eq(1)
        expect(errors[0].type).to eq(:out_of_range)
        expect(errors[0].attribute).to eq(definition.assessment_date_item.field_name)
      end
    end

    it 'should succeed if assessment date is after exit date (exit)' do
      definition = Hmis::Form::Definition.find_by(role: 'EXIT')
      link_id = definition.assessment_date_item.link_id
      assessment_date = (exit_date + 1.day).strftime('%Y-%m-%d')

      date, errors = definition.find_and_validate_assessment_date(hud_values: { link_id => assessment_date }, **default_args)
      expect(date).to eq(exit_date + 1.day)
      expect(errors).to be_empty
    end

    it 'should error if date is invalid/malformed' do
      ['2020', '0020-01-01', '1900-01-01', '2020-18-32'].each do |malformed_date|
        definition = Hmis::Form::Definition.find_by(role: 'INTAKE')
        link_id = definition.assessment_date_item.link_id
        date, errors = definition.find_and_validate_assessment_date(hud_values: { link_id => malformed_date }, **default_args)

        expect(date).to be_nil
        expect(errors.length).to eq(1)
        expect(errors[0].type).to eq(:invalid)
        expect(errors[0].attribute).to eq(definition.assessment_date_item.field_name)
      end
    end
  end
end
