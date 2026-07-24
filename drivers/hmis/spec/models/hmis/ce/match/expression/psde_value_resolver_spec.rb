# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::PsdeValueResolver, type: :model do
  let!(:destination_data_source) { create(:destination_data_source) }
  let!(:hmis_data_source) { create(:hmis_data_source) }
  let(:current_date) { Date.new(2024, 12, 26) }
  let(:configuration) { Hmis::Ce::Configuration.new }
  let(:resolver) { described_class.new(current_date: current_date, configuration: configuration) }

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

  describe 'total_monthly_income resolution' do
    let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::TOTAL_MONTHLY_INCOME }

    def create_income_benefit(**attrs)
      defaults = {
        enrollment: enrollment,
        client: client,
        data_source: hmis_data_source,
        data_collection_stage: 1,
      }
      create(:hmis_income_benefit, :skip_validate, defaults.merge(attrs))
    end

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

    it 'returns nil when IncomeFromAnySource is a non-HUD code (invalid)' do
      create_income_benefit(
        information_date: current_date - 1.week,
        income_from_any_source: 5, # not a valid HUD code
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

    it 'includes income from a non-HMIS source data source linked to the destination client' do
      create_income_benefit(
        information_date: current_date - 2.weeks,
        income_from_any_source: 1,
        total_monthly_income: '100',
      )

      non_hmis_data_source = create(:source_data_source)
      non_hmis_client = create(:hmis_hud_client, data_source: non_hmis_data_source)
      create(
        :hmis_warehouse_client,
        data_source: non_hmis_data_source,
        source: non_hmis_client,
        destination: destination_client,
      )
      non_hmis_enrollment = create(
        :hmis_hud_enrollment,
        data_source: non_hmis_data_source,
        client: non_hmis_client,
        EntryDate: current_date - 1.month,
      )
      create(
        :hmis_income_benefit,
        :skip_validate,
        enrollment: non_hmis_enrollment,
        client: non_hmis_client,
        data_source: non_hmis_data_source,
        information_date: current_date - 1.week,
        income_from_any_source: 1,
        total_monthly_income: '400',
      )

      expect(resolver.call(clients, field)).to eq({ destination_client.id => 400.0 })
    end
  end

  describe 'disability fields' do
    def create_disability(**attrs)
      defaults = {
        enrollment: enrollment,
        client: client,
        data_source: hmis_data_source,
        data_collection_stage: 1,
      }
      create(:hmis_disability, :skip_validate, defaults.merge(attrs))
    end

    # Common behaviors shared by every NoYes disability field. `field` and `disability_type` are
    # provided by each including context.
    shared_examples 'a NoYes disability field' do
      it 'returns nil for clients with no disability rows in scope' do
        expect(resolver.call(clients, field)).to eq({ destination_client.id => nil })
      end

      it 'resolves the latest meaningful Yes (1) response to true' do
        create_disability(disability_type: disability_type, disability_response: 1, information_date: current_date - 1.week)
        result = resolver.call(clients, field)
        expect(result).to eq({ destination_client.id => true })
      end

      it 'resolves the latest meaningful No (0) response to false' do
        create_disability(disability_type: disability_type, disability_response: 0, information_date: current_date - 1.week)
        result = resolver.call(clients, field)
        expect(result).to eq({ destination_client.id => false })
      end

      it 'returns nil when only 8/9/99/nil responses exist' do
        [8, 9, 99, nil].each_with_index do |response, i|
          create_disability(
            disability_type: disability_type,
            disability_response: response,
            information_date: current_date - (i + 1).days,
          )
        end

        expect(resolver.call(clients, field)).to eq({ destination_client.id => nil })
      end

      # Substance use codes (2/3) are not valid for these types. Note this is stricter than the CAS
      # path (GrdaWarehouse::Hud::Client#<type>_response), which accepts 0/1/2/3 for every type.
      it 'returns nil when the only response is a non-HUD code for this disability type' do
        create_disability(disability_type: disability_type, disability_response: 2, information_date: current_date - 1.week)

        expect(resolver.call(clients, field)).to eq({ destination_client.id => nil })
      end

      it 'skips a non-HUD code and falls back to the prior meaningful row' do
        create_disability(
          disability_type: disability_type,
          disability_response: 1,
          information_date: current_date - 2.weeks,
          date_updated: current_date - 2.weeks,
        )
        create_disability(
          disability_type: disability_type,
          disability_response: 2,
          information_date: current_date - 1.week,
          date_updated: current_date - 1.week,
        )

        expect(resolver.call(clients, field)).to eq({ destination_client.id => true })
      end

      it 'skips 8/9/99/nil and falls back to the prior meaningful row' do
        create_disability(
          disability_type: disability_type,
          disability_response: 1,
          information_date: current_date - 2.weeks,
          date_updated: current_date - 2.weeks,
        )
        create_disability(
          disability_type: disability_type,
          disability_response: 9,
          information_date: current_date - 1.week,
          date_updated: current_date - 1.week,
        )

        expect(resolver.call(clients, field)).to eq({ destination_client.id => true })
      end

      it 'excludes disabilities from exited enrollments when lookback is 0' do
        exited_enrollment = create(
          :hmis_hud_enrollment,
          data_source: hmis_data_source,
          client: client,
          EntryDate: current_date - 3.months,
          exit_date: current_date - 1.month,
        )
        create_disability(
          enrollment: exited_enrollment,
          disability_type: disability_type,
          disability_response: 1,
          information_date: current_date - 6.weeks,
        )

        expect(resolver.call(clients, field)).to eq({ destination_client.id => nil })
      end

      it 'excludes disabilities from projects outside a configured project group' do
        out_of_group_project = create(:hmis_hud_project, data_source: hmis_data_source)
        in_group_project = create(:hmis_hud_project, data_source: hmis_data_source)
        project_group = create(:hmis_project_group, data_source: hmis_data_source, with_projects: [in_group_project])
        AppConfigProperty.create!(key: 'hmis_ce/eligibility_project_group_id', value: project_group.id)

        out_of_group_enrollment = create(
          :hmis_hud_enrollment,
          data_source: hmis_data_source,
          client: client,
          project: out_of_group_project,
          EntryDate: current_date - 1.month,
        )
        create_disability(
          enrollment: out_of_group_enrollment,
          disability_type: disability_type,
          disability_response: 1,
          information_date: current_date - 1.week,
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
        create_disability(
          disability_type: disability_type,
          disability_response: 0,
          information_date: current_date - 2.weeks,
        )
        create_disability(
          enrollment: other_enrollment,
          client: other_source_client,
          disability_type: disability_type,
          disability_response: 1,
          information_date: current_date - 1.week,
        )

        expect(resolver.call(clients, field)).to eq({ destination_client.id => true })
      end

      it 'includes disabilities from a non-HMIS source data source linked to the destination client' do
        non_hmis_data_source = create(:source_data_source)
        non_hmis_client = create(:hmis_hud_client, data_source: non_hmis_data_source)
        create(
          :hmis_warehouse_client,
          data_source: non_hmis_data_source,
          source: non_hmis_client,
          destination: destination_client,
        )
        non_hmis_enrollment = create(
          :hmis_hud_enrollment,
          data_source: non_hmis_data_source,
          client: non_hmis_client,
          EntryDate: current_date - 1.month,
        )
        create_disability(
          enrollment: non_hmis_enrollment,
          client: non_hmis_client,
          data_source: non_hmis_data_source,
          disability_type: disability_type,
          disability_response: 1,
          information_date: current_date - 1.week,
        )

        expect(resolver.call(clients, field)).to eq({ destination_client.id => true })
      end
    end

    describe 'mental_health_disorder resolution' do
      let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::MENTAL_HEALTH_DISORDER }
      let(:disability_type) { 9 }

      it_behaves_like 'a NoYes disability field'
    end

    describe 'physical_disability resolution' do
      let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::PHYSICAL_DISABILITY }
      let(:disability_type) { 5 }

      it_behaves_like 'a NoYes disability field'
    end

    describe 'developmental_disability resolution' do
      let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::DEVELOPMENTAL_DISABILITY }
      let(:disability_type) { 6 }

      it_behaves_like 'a NoYes disability field'
    end

    describe 'chronic_health_condition resolution' do
      let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::CHRONIC_HEALTH_CONDITION }
      let(:disability_type) { 7 }

      it_behaves_like 'a NoYes disability field'
    end

    describe 'hiv_aids resolution' do
      let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::HIV_AIDS }
      let(:disability_type) { 8 }

      it_behaves_like 'a NoYes disability field'
    end

    describe 'substance_use_disorder resolution' do
      let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::SUBSTANCE_USE_DISORDER }

      [1, 2, 3].each do |code|
        it "resolves substance code #{code} (Alcohol/Drug/Both) to true" do
          create_disability(
            disability_type: 10,
            disability_response: code,
            information_date: current_date - 1.week,
          )

          expect(resolver.call(clients, field)).to eq({ destination_client.id => true })
        end
      end

      it 'resolves No (0) to false' do
        create_disability(
          disability_type: 10,
          disability_response: 0,
          information_date: current_date - 1.week,
        )

        expect(resolver.call(clients, field)).to eq({ destination_client.id => false })
      end

      it 'skips 8/9/99/nil responses' do
        [8, 9, 99, nil].each_with_index do |response, i|
          create_disability(
            disability_type: 10,
            disability_response: response,
            information_date: current_date - (i + 1).days,
          )
        end

        expect(resolver.call(clients, field)).to eq({ destination_client.id => nil })
      end
    end

    describe 'disability type independence' do
      it 'resolves each disability type from its own most-recent rows' do
        create_disability(
          disability_type: 9, # mental health
          disability_response: 1,
          information_date: current_date - 1.week,
        )
        create_disability(
          disability_type: 5, # physical
          disability_response: 0,
          information_date: current_date - 3.days,
        )

        expect(resolver.call(clients, Hmis::Ce::Match::Expression::PsdeFieldRegistry::MENTAL_HEALTH_DISORDER)).
          to eq({ destination_client.id => true })
        expect(resolver.call(clients, Hmis::Ce::Match::Expression::PsdeFieldRegistry::PHYSICAL_DISABILITY)).
          to eq({ destination_client.id => false })
      end
    end
  end

  describe 'domestic_violence_survivor resolution' do
    let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::DOMESTIC_VIOLENCE_SURVIVOR }

    def create_health_and_dv(**attrs)
      defaults = {
        enrollment: enrollment,
        client: client,
        data_source: hmis_data_source,
        data_collection_stage: 1,
      }
      create(:hmis_health_and_dv, :skip_validate, defaults.merge(attrs))
    end

    it 'returns nil for clients with no HealthAndDV rows in scope' do
      expect(resolver.call(clients, field)).to eq({ destination_client.id => nil })
    end

    it 'resolves the latest meaningful Yes (1) response to true' do
      create_health_and_dv(
        domestic_violence_survivor: 1,
        information_date: current_date - 1.week,
      )

      expect(resolver.call(clients, field)).to eq({ destination_client.id => true })
    end

    it 'resolves the latest meaningful No (0) response to false' do
      create_health_and_dv(
        domestic_violence_survivor: 0,
        information_date: current_date - 1.week,
      )

      expect(resolver.call(clients, field)).to eq({ destination_client.id => false })
    end

    it 'skips 8/9/99/nil and falls back to the prior meaningful row' do
      create_health_and_dv(
        domestic_violence_survivor: 1,
        information_date: current_date - 2.weeks,
        date_updated: current_date - 2.weeks,
      )
      create_health_and_dv(
        domestic_violence_survivor: 99,
        information_date: current_date - 1.week,
        date_updated: current_date - 1.week,
      )

      expect(resolver.call(clients, field)).to eq({ destination_client.id => true })
    end

    it 'excludes DV rows from exited enrollments when lookback is 0' do
      exited_enrollment = create(
        :hmis_hud_enrollment,
        data_source: hmis_data_source,
        client: client,
        EntryDate: current_date - 3.months,
        exit_date: current_date - 1.month,
      )
      create_health_and_dv(
        enrollment: exited_enrollment,
        domestic_violence_survivor: 1,
        information_date: current_date - 6.weeks,
      )

      expect(resolver.call(clients, field)).to eq({ destination_client.id => nil })
    end
  end
end
