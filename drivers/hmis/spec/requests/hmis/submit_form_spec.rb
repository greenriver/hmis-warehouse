# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'
require_relative '../../support/submit_form_spec_helpers'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  # let(:today) { Date.current }

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  before(:each) { hmis_login(user) }

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2020-01-01' }

  # This file tests behavior that is general to all roles. For role-specific tests, see submit_form_*_spec.rb files.
  let(:role) { :ENROLLMENT }
  let(:definition) { Hmis::Form::Definition.find_by(role: role) }
  let(:input) do
    {
      form_definition_id: definition.id,
      record_id: e1.id,
      hud_values: hud_values,
      values: hud_values_to_values_by_link_id(hud_values),
    }
  end

  describe 'SubmitForm general tests' do
    # todo @martha - this should be a shared example
    it 'creates a form processor' do
      expect(Hmis::Form::FormProcessor.where(owner: e1).count).to eq(1)
      expect(e1.form_processor).to be_present
    end

    it 'marks enrollment for re-processing' do
      # delete processing jobs that would have been queued from factory record creation
      Delayed::Job.jobs_for_class(['GrdaWarehouse::Tasks::ServiceHistory::Enrollment', 'GrdaWarehouse::Tasks::IdentifyDuplicates']).delete_all
      # mark enrollment record as processed
      e1.update!(processed_as: 'PROCESSED', processed_hash: 'PROCESSED')

      expect do
        submit_form(input)
        e1.reload
      end.to change(e1, :processed_as).from('PROCESSED').to(nil).
        and change(e1, :processed_hash).from('PROCESSED').to(nil).
        and change(Delayed::Job, :count).by(1)

      # Check that enrollment.processed_as: nil and enrollment.processed_hash: nil, but weren't nil before save
      # this should be true if exit, CLS, Service, or Enrollment changed/added/deleted
      expect(e1.reload.processed_as).to be_nil if role.in?([:ENROLLMENT, :SERVICE, :CURRENT_LIVING_SITUATION])

      # check that delayed jobs are queued for when above happens or client is changed
      expect(Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::ServiceHistory::Enrollment').count).to be_positive if role.in?([:ENROLLMENT, :SERVICE, :CURRENT_LIVING_SITUATION])
      expect(Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::IdentifyDuplicates').count).to be_positive if role.in?([:CLIENT])
    end

    it 'should fail if required field is missing' do
      required_item = find_required_item(definition)
      next unless required_item.present?

      input = test_input.merge(
        values: test_input[:values].merge(required_item.link_id => nil),
        hud_values: test_input[:hud_values].merge(required_item.mapping.field_name => nil),
      )

      expected_error = {
        type: :required,
        attribute: required_item.mapping.field_name,
        severity: :error,
      }
      record, errors = submit_form(input)

      aggregate_failures 'checking response' do
        expect(record).to be_nil
        expect(errors).to include(
          a_hash_including(**expected_error.transform_keys(&:to_s).transform_values(&:to_s)),
        )
      end
    end

    it 'should fail if form definition is draft' do
      draft = create(:hmis_form_definition, version: definition.version + 1, status: Hmis::Form::Definition::DRAFT, identifier: definition.identifier)
      expect_gql_error post_graphql(input: { input: test_input.merge(form_definition_id: draft.id) }) { mutation }
    end

    it 'should update user correctly' do
      next if role == :REFERRAL # skip for referral, tested separately

      if role == :ENROLLMENT
        _response, result = post_graphql(input: { input: test_input.merge(record_id: e1.id) }) { mutation }
      else
        _response, result = post_graphql(input: { input: test_input }) { mutation }
      end

      expect(result.dig('data', 'submitForm', 'errors')).to be_blank
      record_id = result.dig('data', 'submitForm', 'record', 'id')
      record = definition.owner_class.find_by(id: record_id)

      # FIXME refactor this out to its own file test
      if role == :FILE
        expect(record.user).to eq(hmis_user)
        expect(record.updated_by).to eq(hmis_user)
      else
        expect(record.user).to eq(Hmis::Hud::User.from_user(hmis_user))
      end

      next_input = test_input.merge(record_id: record.id)
      record.update(user_id: 999, updated_by_id: nil) if role == :FILE

      _response, result = post_graphql(input: { input: next_input }) { mutation }
      record_id = result.dig('data', 'submitForm', 'record', 'id')
      record = definition.owner_class.find_by(id: record_id)

      if role == :FILE
        expect(record.user_id).to eq(999)
        expect(record.updated_by).to eq(hmis_user)
      else
        expect(record.user).to eq(Hmis::Hud::User.from_user(hmis_user))
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
  c.include SubmitFormSpecHelpers
end
