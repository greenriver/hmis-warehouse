require 'rails_helper'

RSpec.shared_context 'filter criteria setup' do
  # Common fixtures
  let(:user) { create(:acl_user) }
  let(:start_date) { Date.new(2023, 1, 1) }
  let(:end_date) { Date.new(2023, 12, 31) }
  let(:data_source) { create(:data_source_fixed_id) }
  let(:organization) { create(:hud_organization, data_source_id: data_source.id) }
  let(:project) { create_project }

  # Base configuration
  let(:config) { Filters::Criteria::Configuration.new(report_scope_source: GrdaWarehouse::ServiceHistoryEnrollment.entry) }
  let(:scope) { GrdaWarehouse::ServiceHistoryEnrollment.entry }

  # Helper methods
  def create_enrollment_for_client(client, attributes = {})
    create(
      :she_entry, {
        client_id: client.id,
        project_type: 1,
        date: start_date,
        first_date_in_program: start_date,
        last_date_in_program: end_date,
        project_id: project.ProjectID,
        organization_id: organization.OrganizationID,
        data_source_id: data_source.id,
      }.merge(attributes)
    )
  end

  def create_project(attributes = {})
    create(
      :hud_project,
      {
        data_source_id: data_source.id,
        OrganizationID: organization.OrganizationID,
      }.merge(attributes),
    )
  end

  # Common specs
  shared_examples_for 'a criteria that applies conditionally' do |filter_attribute, filter_value, defaults = {}|
    describe '#applies?' do
      it 'returns true when the filter attribute is present' do
        filter_params = defaults.merge({ user_id: user.id })
        filter_params[filter_attribute] = filter_value
        filter = ::Filters::FilterBase.new(filter_params)
        criteria = described_class.new(input: filter, config: config)

        expect(criteria.applies?).to be true
      end

      it 'returns false when the filter attribute is not present' do
        filter_params = defaults.merge({ user_id: user.id })
        empty_filter = ::Filters::FilterBase.new(filter_params)
        empty_criteria = described_class.new(input: empty_filter, config: config)

        expect(empty_criteria.applies?).to be false
      end
    end
  end

  shared_examples_for 'a criteria that always applies' do
    describe '#applies?' do
      it 'always returns true' do
        empty_filter = ::Filters::FilterBase.new(user_id: user.id)
        criteria = described_class.new(input: empty_filter, config: config)

        expect(criteria.applies?).to be true
      end
    end
  end
end
