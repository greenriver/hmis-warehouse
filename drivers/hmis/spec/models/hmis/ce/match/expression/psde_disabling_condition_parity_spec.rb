# frozen_string_literal: true

require 'rails_helper'

# Asserts that psde.any_reported_disability agrees with the value the warehouse sends to CAS as
# "disabling condition" (GrdaWarehouse::Hud::Client.disabled_client_scope) when every enrollment is in the
# CE eligibility scope. CE is three-valued and the warehouse is two-valued, so a CE nil is compared as
# warehouse false.
#
# psde.disabling_condition (HUD definition) shares this algorithm but has no warehouse counterpart with the same
# "latest answer" semantics, so its row test is checked against GrdaWarehouse::Hud::Disability#indefinite_and_impairs?
# in disabling_condition_inference_spec.rb instead.
RSpec.describe Hmis::Ce::Match::Expression::PsdeValueResolver, type: :model do
  let!(:destination_data_source) { create(:destination_data_source) }
  let!(:hmis_data_source) { create(:hmis_data_source) }
  let!(:other_data_source) { create(:source_data_source) }
  let(:current_date) { Date.current }
  let(:configuration) { Hmis::Ce::Configuration.new }
  let(:resolver) { described_class.new(current_date: current_date, configuration: configuration) }
  let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::ANY_REPORTED_DISABILITY }

  before do
    allow(configuration).to receive(:eligibility_lookback_months).and_return(12)
    allow(configuration).to receive(:eligibility_project_group).and_return(nil)
  end

  def create_source_client(data_source: hmis_data_source, destination: nil)
    if destination
      source_client = create(:hmis_hud_client, data_source: data_source)
      create(
        :hmis_warehouse_client,
        data_source: data_source,
        source: source_client,
        destination: destination,
      )
      source_client
    else
      create(:hmis_hud_client_with_warehouse_client, data_source: data_source)
    end
  end

  # Completed (exited, non-WIP) enrollment inside the 12-month lookback window.
  def create_enrollment(source_client, entry_months_ago:, disabling_condition: 99)
    create(
      :hmis_hud_enrollment,
      data_source: source_client.data_source,
      client: source_client,
      DisablingCondition: disabling_condition,
      EntryDate: current_date - entry_months_ago.months,
      exit_date: current_date - (entry_months_ago - 1).months,
    )
  end

  def create_disability(enrollment, type:, response:, weeks_ago:)
    create(
      :hmis_disability,
      :skip_validate,
      enrollment: enrollment,
      client: enrollment.client,
      data_source: enrollment.data_source,
      data_collection_stage: 1,
      disability_type: type,
      disability_response: response,
      information_date: current_date - weeks_ago.weeks,
    )
  end

  # Each scenario builds one destination client and returns [destination_client, expected CE value].
  let(:scenarios) do
    {
      'enrollment Yes' => lambda do
        source = create_source_client
        create_enrollment(source, entry_months_ago: 3, disabling_condition: 1)
        [source.destination_client, true]
      end,
      'enrollment No' => lambda do
        source = create_source_client
        create_enrollment(source, entry_months_ago: 3, disabling_condition: 0)
        [source.destination_client, false]
      end,
      'older enrollment Yes, newer enrollment No' => lambda do
        source = create_source_client
        create_enrollment(source, entry_months_ago: 6, disabling_condition: 1)
        create_enrollment(source, entry_months_ago: 3, disabling_condition: 0)
        [source.destination_client, false]
      end,
      'older enrollment Yes, newer enrollment 99' => lambda do
        source = create_source_client
        create_enrollment(source, entry_months_ago: 6, disabling_condition: 1)
        create_enrollment(source, entry_months_ago: 3, disabling_condition: 99)
        [source.destination_client, true]
      end,
      'disability Yes then later 8 and 9' => lambda do
        source = create_source_client
        enrollment = create_enrollment(source, entry_months_ago: 3)
        create_disability(enrollment, type: 6, response: 1, weeks_ago: 11)
        create_disability(enrollment, type: 6, response: 8, weeks_ago: 10)
        create_disability(enrollment, type: 6, response: 9, weeks_ago: 9)
        [source.destination_client, true]
      end,
      'enrollment No, disability Yes' => lambda do
        source = create_source_client
        enrollment = create_enrollment(source, entry_months_ago: 3, disabling_condition: 0)
        create_disability(enrollment, type: 9, response: 1, weeks_ago: 10)
        [source.destination_client, true]
      end,
      'disability Yes then later No' => lambda do
        source = create_source_client
        enrollment = create_enrollment(source, entry_months_ago: 3)
        create_disability(enrollment, type: 5, response: 1, weeks_ago: 11)
        create_disability(enrollment, type: 5, response: 0, weeks_ago: 10)
        [source.destination_client, false]
      end,
      'disability same-day Yes and No' => lambda do
        source = create_source_client
        enrollment = create_enrollment(source, entry_months_ago: 3)
        create_disability(enrollment, type: 7, response: 0, weeks_ago: 10)
        create_disability(enrollment, type: 7, response: 1, weeks_ago: 10)
        [source.destination_client, true]
      end,
      'substance use Both' => lambda do
        source = create_source_client
        enrollment = create_enrollment(source, entry_months_ago: 3)
        create_disability(enrollment, type: 10, response: 3, weeks_ago: 10)
        [source.destination_client, true]
      end,
      'no meaningful responses' => lambda do
        source = create_source_client
        enrollment = create_enrollment(source, entry_months_ago: 3, disabling_condition: 8)
        create_disability(enrollment, type: 9, response: 9, weeks_ago: 10)
        [source.destination_client, nil]
      end,
      'two source clients: Yes, then later No of the same type in another data source' => lambda do
        source = create_source_client
        destination = source.destination_client
        other_source = create_source_client(data_source: other_data_source, destination: destination)
        enrollment = create_enrollment(source, entry_months_ago: 6)
        other_enrollment = create_enrollment(other_source, entry_months_ago: 3, disabling_condition: 0)
        create_disability(enrollment, type: 9, response: 1, weeks_ago: 24)
        create_disability(other_enrollment, type: 9, response: 0, weeks_ago: 10)
        [destination, false]
      end,
    }
  end

  it 'matches GrdaWarehouse::Hud::Client.disabled_client_scope for every scenario' do
    expected_by_scenario = scenarios.transform_values(&:call)

    enrollment_ids = Hmis::Hud::Enrollment.pluck(:id)
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.where(id: enrollment_ids).each(&:rebuild_service_history!)

    client_ids = expected_by_scenario.values.map { |destination, _expected| destination.id }
    ce_values = resolver.call(GrdaWarehouse::Hud::Client.where(id: client_ids), field)

    aggregate_failures do
      expected_by_scenario.each do |scenario, (destination, expected)|
        ce_value = ce_values.fetch(destination.id)
        warehouse_disabled = GrdaWarehouse::Hud::Client.disabled_client_scope(client_ids: destination.id).exists?

        expect(ce_value).to eq(expected), "#{scenario}: expected CE value #{expected.inspect}, got #{ce_value.inspect}"
        expect(ce_value == true).to eq(warehouse_disabled),
                                    "#{scenario}: CE #{ce_value.inspect} disagrees with warehouse #{warehouse_disabled}"
      end
    end
  end
end
