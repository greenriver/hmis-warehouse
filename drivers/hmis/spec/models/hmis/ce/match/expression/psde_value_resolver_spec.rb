# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::PsdeValueResolver, type: :model do
  let!(:destination_data_source) { create(:destination_data_source) }
  let!(:hmis_data_source) { create(:hmis_data_source) }
  let(:current_date) { Date.new(2024, 12, 26) }
  let(:configuration) { Hmis::Ce::Configuration.new }
  let(:resolver) { described_class.new(current_date: current_date, configuration: configuration) }
  let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::MONTHLY_TOTAL_INCOME }

  let(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: hmis_data_source) }
  let(:destination_client) { client.destination_client }
  let(:clients) { GrdaWarehouse::Hud::Client.where(id: destination_client.id) }

  let!(:enrollment) do
    create(
      :hmis_hud_enrollment,
      data_source: hmis_data_source,
      client: client,
      EntryDate: current_date - 1.month,
    )
  end

  def create_income_benefit(**attrs)
    defaults = {
      enrollment: enrollment,
      client: client,
      data_source: hmis_data_source,
      data_collection_stage: 1,
    }
    create(:hmis_income_benefit, :skip_validate, defaults.merge(attrs))
  end

  describe '#call' do
    it 'returns nil for clients with no income benefits in scope' do
      expect(resolver.call(clients, field)).to eq({ destination_client.id => nil })
    end

    it 'returns nil when only income rows have invalid IncomeFromAnySource values' do
      create_income_benefit(
        information_date: current_date - 1.week,
        income_from_any_source: 9,
        total_monthly_income: '500',
      )

      expect(resolver.call(clients, field)).to eq({ destination_client.id => nil })
    end

    context 'locked income scenarios' do
      it 'resolves 0 when latest valid row is IncomeFromAnySource: No after Yes/$500' do
        create_income_benefit(
          information_date: current_date - 2.weeks,
          income_from_any_source: 1,
          total_monthly_income: '500',
          date_updated: current_date - 2.weeks,
        )
        create_income_benefit(
          information_date: current_date - 1.week,
          income_from_any_source: 0, # No income
          total_monthly_income: nil,
          date_updated: current_date - 1.week,
        )

        expect(resolver.call(clients, field)).to eq({ destination_client.id => 0 })
      end

      it 'skips refused row and uses prior latest valid Yes/$500' do
        create_income_benefit(
          information_date: current_date - 2.weeks,
          income_from_any_source: 1,
          total_monthly_income: '500',
          date_updated: current_date - 2.weeks,
        )
        create_income_benefit(
          information_date: current_date - 1.week,
          income_from_any_source: 9,
          total_monthly_income: nil,
          date_updated: current_date - 1.week,
        )

        expect(resolver.call(clients, field)).to eq({ destination_client.id => 500.0 })
      end

      it 'skips refused row and uses prior latest valid No/nil' do
        create_income_benefit(
          information_date: current_date - 2.weeks,
          income_from_any_source: 0, # No income
          total_monthly_income: nil,
          date_updated: current_date - 2.weeks,
        )
        create_income_benefit(
          information_date: current_date - 1.week,
          income_from_any_source: 9,
          total_monthly_income: nil,
          date_updated: current_date - 1.week,
        )

        expect(resolver.call(clients, field)).to eq({ destination_client.id => 0 })
      end

      it 'resolves 0 for Yes/$0 data quality edge case' do
        create_income_benefit(
          information_date: current_date - 1.week,
          income_from_any_source: 1,
          total_monthly_income: '0',
        )

        expect(resolver.call(clients, field)).to eq({ destination_client.id => 0 })
      end

      it 'skips Yes with nil MonthlyTotalIncome as invalid and uses prior Yes/$500' do
        create_income_benefit(
          information_date: current_date - 2.weeks,
          income_from_any_source: 1,
          total_monthly_income: '500',
          date_updated: current_date - 2.weeks,
        )
        create_income_benefit(
          information_date: current_date - 1.week,
          income_from_any_source: 1,
          total_monthly_income: nil,
          date_updated: current_date - 1.week,
        )

        expect(resolver.call(clients, field)).to eq({ destination_client.id => 500.0 })
      end

      it 'returns nil when only Yes with nil MonthlyTotalIncome is present' do
        create_income_benefit(
          information_date: current_date - 1.week,
          income_from_any_source: 1,
          total_monthly_income: nil,
        )

        expect(resolver.call(clients, field)).to eq({ destination_client.id => nil })
      end
    end

    it 'breaks ties by DateUpdated then id when InformationDate matches' do
      shared_date = current_date - 1.week

      create_income_benefit(
        information_date: shared_date,
        income_from_any_source: 1,
        total_monthly_income: '100',
        date_updated: shared_date,
      )
      create_income_benefit(
        information_date: shared_date,
        income_from_any_source: 1,
        total_monthly_income: '200',
        date_updated: shared_date + 1.day,
      )

      expect(resolver.call(clients, field)).to eq({ destination_client.id => 200.0 })
    end

    it 'excludes income from exited enrollments when lookback is 0' do
      exited_enrollment = create(
        :hmis_hud_enrollment,
        data_source: hmis_data_source,
        client: client,
        EntryDate: current_date - 3.months,
        exit_date: current_date - 1.month,
      )
      create(
        :hmis_income_benefit,
        :skip_validate,
        enrollment: exited_enrollment,
        client: client,
        data_source: hmis_data_source,
        information_date: current_date - 6.weeks,
        income_from_any_source: 1,
        total_monthly_income: '500',
      )

      expect(resolver.call(clients, field)).to eq({ destination_client.id => nil })
    end

    it 'aggregates across merged source clients for a destination client' do
      other_source_client = create(:hmis_hud_client, data_source: hmis_data_source)
      create(
        :hmis_warehouse_client,
        data_source: hmis_data_source,
        source: other_source_client,
        destination: destination_client,
      )
      other_enrollment = create(
        :hmis_hud_enrollment,
        data_source: hmis_data_source,
        client: other_source_client,
        EntryDate: current_date - 1.month,
      )
      create(
        :hmis_income_benefit,
        :skip_validate,
        enrollment: enrollment,
        client: client,
        data_source: hmis_data_source,
        information_date: current_date - 2.weeks,
        income_from_any_source: 1,
        total_monthly_income: '100',
      )
      create(
        :hmis_income_benefit,
        :skip_validate,
        enrollment: other_enrollment,
        client: other_source_client,
        data_source: hmis_data_source,
        information_date: current_date - 1.week,
        income_from_any_source: 1,
        total_monthly_income: '300',
      )

      expect(resolver.call(clients, field)).to eq({ destination_client.id => 300.0 })
    end
  end
end
