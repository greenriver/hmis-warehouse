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

  describe 'hiv_aids_values_in_window resolution' do
    let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::HIV_AIDS_VALUES_IN_WINDOW }
    let(:latest_field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::HIV_AIDS }
    let(:disability_type) { 8 }

    def create_disability(**attrs)
      defaults = {
        enrollment: enrollment,
        client: client,
        data_source: hmis_data_source,
        data_collection_stage: 1,
      }
      create(:hmis_disability, :skip_validate, defaults.merge(attrs))
    end

    it 'returns an empty array for clients with no disability rows in scope' do
      expect(resolver.call(clients, field)).to eq({ destination_client.id => [] })
    end

    it 'keeps every meaningful value within a single enrollment (Yes then No => both kept)' do
      create_disability(
        disability_type: disability_type,
        disability_response: 1,
        information_date: current_date - 2.weeks,
        date_updated: current_date - 2.weeks,
      )
      create_disability(
        disability_type: disability_type,
        disability_response: 0,
        information_date: current_date - 1.week,
        date_updated: current_date - 1.week,
      )

      expect(resolver.call(clients, field)[destination_client.id]).to eq([false, true]) # most recent is first
      expect(resolver.call(clients, latest_field)).to eq({ destination_client.id => false }) # `latest` field still returns false
    end

    it 'returns meaningful values newest-first, deduplicated by boolean' do
      create_disability(
        disability_type: disability_type,
        disability_response: 1,
        information_date: current_date - 3.weeks,
        date_updated: current_date - 3.weeks,
      )
      create_disability(
        disability_type: disability_type,
        disability_response: 1,
        information_date: current_date - 2.weeks,
        date_updated: current_date - 2.weeks,
      )
      create_disability(
        disability_type: disability_type,
        disability_response: 0,
        information_date: current_date - 1.week,
        date_updated: current_date - 1.week,
      )

      expect(resolver.call(clients, field)).to eq({ destination_client.id => [false, true] })
    end

    it 'includes true when one enrollment is Yes and another is No, even if latest across all is No' do
      other_enrollment = create(
        :hmis_hud_enrollment,
        data_source: hmis_data_source,
        client: client,
        EntryDate: current_date - 2.months,
      )
      create_disability(
        disability_type: disability_type,
        disability_response: 1,
        information_date: current_date - 2.weeks,
        date_updated: current_date - 2.weeks,
      )
      create_disability(
        enrollment: other_enrollment,
        disability_type: disability_type,
        disability_response: 0,
        information_date: current_date - 1.week,
        date_updated: current_date - 1.week,
      )

      result = resolver.call(clients, field)
      expect(result[destination_client.id]).to contain_exactly(true, false)
      expect(resolver.call(clients, latest_field)).to eq({ destination_client.id => false }) # `latest` field still returns false
    end

    it 'returns [false] when all meaningful values are No' do
      create_disability(
        disability_type: disability_type,
        disability_response: 0,
        information_date: current_date - 1.week,
      )

      expect(resolver.call(clients, field)).to eq({ destination_client.id => [false] })
    end

    it 'returns an empty array when only 8/9/99/nil responses exist' do
      [8, 9, 99, nil].each_with_index do |response, i|
        create_disability(
          disability_type: disability_type,
          disability_response: response,
          information_date: current_date - (i + 1).days,
        )
      end

      expect(resolver.call(clients, field)).to eq({ destination_client.id => [] })
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

      expect(resolver.call(clients, field)).to eq({ destination_client.id => [] })
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

      expect(resolver.call(clients, field)[destination_client.id]).to contain_exactly(false, true)
    end
  end

  describe 'substance_use_disorder_values_in_window resolution' do
    let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::SUBSTANCE_USE_DISORDER_VALUES_IN_WINDOW }

    def create_disability(**attrs)
      defaults = {
        enrollment: enrollment,
        client: client,
        data_source: hmis_data_source,
        data_collection_stage: 1,
      }
      create(:hmis_disability, :skip_validate, defaults.merge(attrs))
    end

    it 'resolves Drug (2) to true' do
      create_disability(
        disability_type: 10,
        disability_response: 2,
        information_date: current_date - 1.week,
      )

      expect(resolver.call(clients, field)).to eq({ destination_client.id => [true] })
    end
  end

  describe 'domestic_violence_survivor_values_in_window resolution' do
    let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::DOMESTIC_VIOLENCE_SURVIVOR_VALUES_IN_WINDOW }

    def create_health_and_dv(**attrs)
      defaults = {
        enrollment: enrollment,
        client: client,
        data_source: hmis_data_source,
        data_collection_stage: 1,
      }
      create(:hmis_health_and_dv, :skip_validate, defaults.merge(attrs))
    end

    it 'reads from HealthAndDV, not Disabilities' do
      create_health_and_dv(
        domestic_violence_survivor: 1,
        information_date: current_date - 1.week,
      )

      expect(resolver.call(clients, field)).to eq({ destination_client.id => [true] })
    end
  end

  shared_context 'with disabling condition helpers' do
    def create_disability(**attrs)
      defaults = {
        enrollment: enrollment,
        client: client,
        data_source: hmis_data_source,
        data_collection_stage: 1,
      }
      create(:hmis_disability, :skip_validate, defaults.merge(attrs))
    end

    def create_enrollment(**attrs)
      defaults = {
        data_source: hmis_data_source,
        client: client,
        EntryDate: current_date - 1.month,
      }
      create(:hmis_hud_enrollment, defaults.merge(attrs))
    end

    def resolved_value
      resolver.call(clients, field).fetch(destination_client.id)
    end

    def configure_project_group(projects)
      project_group = create(:hmis_project_group, data_source: hmis_data_source, with_projects: projects)
      AppConfigProperty.create!(key: 'hmis_ce/eligibility_project_group_id', value: project_group.id)
    end
  end

  # Both disabling condition fields share one algorithm and differ only in the per-row qualify test. This block
  # covers the shared algorithm through the broad field; the HUD block below covers the HUD row test.
  describe 'any_reported_disability resolution' do
    let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::ANY_REPORTED_DISABILITY }

    include_context 'with disabling condition helpers'

    it 'returns nil when there is no meaningful data in scope' do
      expect(resolver.call(clients, field)).to eq({ destination_client.id => nil })
    end

    describe 'rule A: enrollment DisablingCondition' do
      it 'resolves the latest answered enrollment Yes to true' do
        enrollment.update!(DisablingCondition: 1)

        expect(resolved_value).to be(true)
      end

      it 'resolves the latest answered enrollment No to false' do
        enrollment.update!(DisablingCondition: 0)

        expect(resolved_value).to be(false)
      end

      it 'uses the enrollment with the latest EntryDate' do
        enrollment.update!(DisablingCondition: 1)
        create_enrollment(DisablingCondition: 0, EntryDate: current_date - 1.week)

        expect(resolved_value).to be(false)
      end

      it 'skips later enrollments answered 8/9/99' do
        enrollment.update!(DisablingCondition: 1)
        [8, 9, 99].each_with_index do |response, i|
          create_enrollment(DisablingCondition: response, EntryDate: current_date - (i + 1).days)
        end

        expect(resolved_value).to be(true)
      end

      it 'breaks EntryDate ties by DateUpdated' do
        enrollment.update_columns(DisablingCondition: 0, DateUpdated: current_date.to_time)
        later_entry = create_enrollment(DisablingCondition: 1, EntryDate: current_date - 1.week)
        later_entry_tie = create_enrollment(DisablingCondition: 0, EntryDate: current_date - 1.week)
        later_entry.update_columns(DateUpdated: current_date.to_time)
        later_entry_tie.update_columns(DateUpdated: (current_date - 1.day).to_time)

        expect(resolved_value).to be(true)
      end

      it 'breaks EntryDate and DateUpdated ties by id' do
        shared_updated_at = current_date.to_time
        older = create_enrollment(DisablingCondition: 0, EntryDate: current_date - 1.week)
        newer = create_enrollment(DisablingCondition: 1, EntryDate: current_date - 1.week)
        older.update_columns(DateUpdated: shared_updated_at)
        newer.update_columns(DateUpdated: shared_updated_at)

        expect(resolved_value).to be(true)
      end

      it 'does not let a null DateUpdated win the tiebreak' do
        with_date = create_enrollment(DisablingCondition: 0, EntryDate: current_date - 1.week)
        without_date = create_enrollment(DisablingCondition: 1, EntryDate: current_date - 1.week)
        with_date.update_columns(DateUpdated: current_date.to_time)
        without_date.update_columns(DateUpdated: nil)

        expect(resolved_value).to be(false)
      end
    end

    describe 'rule B: disability records' do
      it 'resolves a Yes overridden by a later No of the same type to false' do
        create_disability(disability_type: 9, disability_response: 1, information_date: current_date - 2.weeks)
        create_disability(disability_type: 9, disability_response: 0, information_date: current_date - 1.week)

        expect(resolved_value).to be(false)
      end

      it 'resolves a Yes followed by a later Yes of the same type to true' do
        create_disability(disability_type: 9, disability_response: 1, information_date: current_date - 2.weeks)
        create_disability(disability_type: 9, disability_response: 1, information_date: current_date - 1.week)

        expect(resolved_value).to be(true)
      end

      it 'lets a Yes win a same-day tie with a No, regardless of which was updated last' do
        create_disability(
          disability_type: 9,
          disability_response: 1,
          information_date: current_date - 1.week,
          date_updated: current_date - 1.week,
        )
        create_disability(
          disability_type: 9,
          disability_response: 0,
          information_date: current_date - 1.week,
          date_updated: current_date - 1.day,
        )

        expect(resolved_value).to be(true)
      end

      [2, 3].each do |response|
        it "counts substance use response #{response} as Yes" do
          create_disability(disability_type: 10, disability_response: response, information_date: current_date - 1.week)

          expect(resolved_value).to be(true)
        end
      end

      [2, 3].each do |response|
        it "counts response #{response} on a type other than substance use as Yes" do
          create_disability(disability_type: 5, disability_response: response, information_date: current_date - 1.week)

          expect(resolved_value).to be(true)
        end
      end

      it 'treats disability types independently' do
        create_disability(disability_type: 5, disability_response: 1, information_date: current_date - 2.weeks)
        create_disability(disability_type: 9, disability_response: 0, information_date: current_date - 1.week)

        expect(resolved_value).to be(true)
      end

      it 'ignores disability types outside 5-10' do
        create_disability(disability_type: 4, disability_response: 1, information_date: current_date - 1.week)

        expect(resolved_value).to be_nil
      end

      it 'ignores 8/9/99 responses' do
        create_disability(disability_type: 9, disability_response: 1, information_date: current_date - 2.weeks)
        create_disability(disability_type: 9, disability_response: 8, information_date: current_date - 1.week)

        expect(resolved_value).to be(true)
      end

      it 'skips rows with a null InformationDate without raising' do
        create_disability(disability_type: 9, disability_response: 1, information_date: nil)
        create_disability(disability_type: 9, disability_response: 0, information_date: current_date - 1.week)

        expect(resolved_value).to be(false)
      end
    end

    describe 'combining rules' do
      it 'resolves to true when A is No and B is Yes' do
        enrollment.update!(DisablingCondition: 0)
        create_disability(disability_type: 9, disability_response: 1, information_date: current_date - 1.week)

        expect(resolved_value).to be(true)
      end

      it 'resolves to true when A is Yes and B is No' do
        enrollment.update!(DisablingCondition: 1)
        create_disability(disability_type: 9, disability_response: 0, information_date: current_date - 1.week)

        expect(resolved_value).to be(true)
      end

      it 'resolves to false when A is unknown and B only has No responses' do
        create_disability(disability_type: 9, disability_response: 0, information_date: current_date - 1.week)

        expect(resolved_value).to be(false)
      end

      it 'resolves to false when A is No and B is unknown' do
        enrollment.update!(DisablingCondition: 0)

        expect(resolved_value).to be(false)
      end
    end

    describe 'eligibility scope' do
      it 'ignores data outside the lookback window' do
        allow(configuration).to receive(:eligibility_lookback_months).and_return(3)
        enrollment.destroy!
        old_enrollment = create_enrollment(
          DisablingCondition: 1,
          EntryDate: current_date - 1.year,
          exit_date: current_date - 6.months,
        )
        create_disability(
          enrollment: old_enrollment,
          disability_type: 9,
          disability_response: 1,
          information_date: current_date - 1.year,
        )

        expect(resolved_value).to be_nil
      end

      it 'includes data from exited enrollments inside the lookback window' do
        allow(configuration).to receive(:eligibility_lookback_months).and_return(3)
        create_enrollment(
          DisablingCondition: 1,
          EntryDate: current_date - 4.months,
          exit_date: current_date - 2.months,
        )

        expect(resolved_value).to be(true)
      end

      it 'ignores data from projects outside the project group' do
        in_group_project = create(:hmis_hud_project, data_source: hmis_data_source)
        configure_project_group([in_group_project])
        enrollment.update!(DisablingCondition: 1)
        create_disability(disability_type: 9, disability_response: 1, information_date: current_date - 1.week)

        expect(resolved_value).to be_nil
      end

      it 'does not let an out-of-scope later No override an in-scope Yes' do
        in_group_project = create(:hmis_hud_project, data_source: hmis_data_source)
        configure_project_group([in_group_project])
        in_group_enrollment = create_enrollment(
          project: in_group_project,
          DisablingCondition: 1,
          EntryDate: current_date - 2.months,
        )
        create_disability(
          enrollment: in_group_enrollment,
          disability_type: 9,
          disability_response: 1,
          information_date: current_date - 2.weeks,
        )
        # Out-of-group enrollment (the default `enrollment`) is later and says No on both rules
        enrollment.update!(DisablingCondition: 0)
        create_disability(disability_type: 9, disability_response: 0, information_date: current_date - 1.week)

        expect(resolved_value).to be(true)
      end

      it 'includes WIP enrollments' do
        enrollment.destroy!
        create(
          :hmis_hud_wip_enrollment,
          data_source: hmis_data_source,
          client: client,
          DisablingCondition: 1,
          EntryDate: current_date - 1.week,
        )

        expect(resolved_value).to be(true)
      end

      it 'includes disability records on WIP enrollments' do
        enrollment.destroy!
        wip_enrollment = create(
          :hmis_hud_wip_enrollment,
          data_source: hmis_data_source,
          client: client,
          DisablingCondition: 99,
          EntryDate: current_date - 1.week,
        )
        create_disability(
          enrollment: wip_enrollment,
          disability_type: 9,
          disability_response: 1,
          information_date: current_date - 1.week,
        )

        expect(resolved_value).to be(true)
      end
    end

    describe 'multiple source clients' do
      let(:other_data_source) { create(:source_data_source) }
      let(:other_source_client) { create(:hmis_hud_client, data_source: other_data_source) }
      let(:other_enrollment) do
        create(
          :hmis_hud_enrollment,
          data_source: other_data_source,
          client: other_source_client,
          EntryDate: current_date - 1.month,
        )
      end

      before do
        create(
          :hmis_warehouse_client,
          data_source: other_data_source,
          source: other_source_client,
          destination: destination_client,
        )
      end

      def create_other_disability(**attrs)
        create_disability(
          enrollment: other_enrollment,
          client: other_source_client,
          data_source: other_data_source,
          **attrs,
        )
      end

      it 'lets a later No in another data source override a Yes of the same type' do
        create_disability(disability_type: 9, disability_response: 1, information_date: current_date - 2.weeks)
        create_other_disability(disability_type: 9, disability_response: 0, information_date: current_date - 1.week)

        expect(resolved_value).to be(false)
      end

      it 'lets a later Yes in another data source override a No of the same type' do
        create_disability(disability_type: 9, disability_response: 0, information_date: current_date - 2.weeks)
        create_other_disability(disability_type: 9, disability_response: 1, information_date: current_date - 1.week)

        expect(resolved_value).to be(true)
      end

      it 'uses the latest answered enrollment across source clients' do
        enrollment.update!(DisablingCondition: 1)
        other_enrollment.update!(DisablingCondition: 0, EntryDate: current_date - 1.week)

        expect(resolved_value).to be(false)
      end
    end

    describe 'batch resolution' do
      def create_client_with_enrollment(disabling_condition:)
        source_client = create(:hmis_hud_client_with_warehouse_client, data_source: hmis_data_source)
        create(
          :hmis_hud_enrollment,
          data_source: hmis_data_source,
          client: source_client,
          DisablingCondition: disabling_condition,
          EntryDate: current_date - 1.month,
        )
        source_client.destination_client
      end

      it 'resolves every requested client in one call' do
        enrollment.update!(DisablingCondition: 1)
        no_client = create_client_with_enrollment(disabling_condition: 0)
        unknown_client = create_client_with_enrollment(disabling_condition: 99)
        client_ids = [destination_client.id, no_client.id, unknown_client.id]

        result = resolver.call(GrdaWarehouse::Hud::Client.where(id: client_ids), field)

        expect(result).to eq(
          destination_client.id => true,
          no_client.id => false,
          unknown_client.id => nil,
        )
      end
    end
  end

  # Rule A, the eligibility scope and the response codes are shared by both fields. The any_reported_disability
  # block above covers them in full; these spot-checks confirm they apply to disabling_condition too. They use
  # disability rows that qualify under either row test.
  describe 'disabling_condition shared rules' do
    let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::DISABLING_CONDITION }

    include_context 'with disabling condition helpers'

    it 'resolves the latest answered enrollment DisablingCondition' do
      enrollment.update!(DisablingCondition: 1)
      create_enrollment(DisablingCondition: 0, EntryDate: current_date - 1.week)

      expect(resolved_value).to be(false)
    end

    it 'skips enrollments answered 8/9/99' do
      enrollment.update!(DisablingCondition: 1)
      create_enrollment(DisablingCondition: 99, EntryDate: current_date - 1.week)

      expect(resolved_value).to be(true)
    end

    it 'ignores data outside the lookback window' do
      allow(configuration).to receive(:eligibility_lookback_months).and_return(3)
      enrollment.destroy!
      old_enrollment = create_enrollment(
        DisablingCondition: 1,
        EntryDate: current_date - 1.year,
        exit_date: current_date - 6.months,
      )
      create_disability(
        enrollment: old_enrollment,
        disability_type: 6,
        disability_response: 1,
        information_date: current_date - 1.year,
      )

      expect(resolved_value).to be_nil
    end

    it 'ignores data from projects outside the project group' do
      in_group_project = create(:hmis_hud_project, data_source: hmis_data_source)
      configure_project_group([in_group_project])
      enrollment.update!(DisablingCondition: 1)
      create_disability(disability_type: 6, disability_response: 1, information_date: current_date - 1.week)

      expect(resolved_value).to be_nil
    end

    it 'includes WIP enrollments' do
      enrollment.destroy!
      create(
        :hmis_hud_wip_enrollment,
        data_source: hmis_data_source,
        client: client,
        DisablingCondition: 1,
        EntryDate: current_date - 1.week,
      )

      expect(resolved_value).to be(true)
    end

    [2, 3].each do |response|
      it "counts response #{response} on a type other than substance use as Yes" do
        create_disability(
          disability_type: 5,
          disability_response: response,
          indefinite_and_impairs: 1,
          information_date: current_date - 1.week,
        )

        expect(resolved_value).to be(true)
      end
    end
  end

  describe 'disabling_condition (HUD) resolution' do
    include_context 'with disabling condition helpers'

    let(:field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::DISABLING_CONDITION }

    # Physical, Chronic Health, Mental Health, Substance Use
    impairment_dependent_types = [5, 7, 9, 10]
    # Developmental, HIV/AIDS
    always_qualifying_types = [6, 8]

    impairment_dependent_types.each do |type|
      it "resolves type #{type} Yes with IndefiniteAndImpairs Yes to true" do
        create_disability(
          disability_type: type,
          disability_response: 1,
          indefinite_and_impairs: 1,
          information_date: current_date - 1.week,
        )

        expect(resolved_value).to be(true)
      end

      it "resolves type #{type} Yes with IndefiniteAndImpairs No to false" do
        create_disability(
          disability_type: type,
          disability_response: 1,
          indefinite_and_impairs: 0,
          information_date: current_date - 1.week,
        )

        expect(resolved_value).to be(false)
      end

      # An unanswered follow-up is missing data, so the row is not an answer
      [8, 9, 99, nil].each do |indefinite_and_impairs|
        it "resolves type #{type} Yes with IndefiniteAndImpairs #{indefinite_and_impairs.inspect} to nil" do
          create_disability(
            disability_type: type,
            disability_response: 1,
            indefinite_and_impairs: indefinite_and_impairs,
            information_date: current_date - 1.week,
          )

          expect(resolved_value).to be_nil
        end
      end
    end

    always_qualifying_types.each do |type|
      [nil, 0].each do |indefinite_and_impairs|
        it "resolves type #{type} Yes with IndefiniteAndImpairs #{indefinite_and_impairs.inspect} to true" do
          create_disability(
            disability_type: type,
            disability_response: 1,
            indefinite_and_impairs: indefinite_and_impairs,
            information_date: current_date - 1.week,
          )

          expect(resolved_value).to be(true)
        end
      end
    end

    [2, 3].each do |response|
      it "resolves substance use response #{response} with IndefiniteAndImpairs Yes to true" do
        create_disability(
          disability_type: 10,
          disability_response: response,
          indefinite_and_impairs: 1,
          information_date: current_date - 1.week,
        )

        expect(resolved_value).to be(true)
      end
    end

    describe 'replacement by later rows of the same type' do
      it 'lets a later Yes with IndefiniteAndImpairs No replace a qualifying Yes' do
        create_disability(
          disability_type: 9,
          disability_response: 1,
          indefinite_and_impairs: 1,
          information_date: current_date - 2.weeks,
        )
        create_disability(
          disability_type: 9,
          disability_response: 1,
          indefinite_and_impairs: 0,
          information_date: current_date - 1.week,
        )

        expect(resolved_value).to be(false)
      end

      [8, 9, 99, nil].each do |later_indefinite_and_impairs|
        it "does not let a later Yes with IndefiniteAndImpairs #{later_indefinite_and_impairs.inspect} " \
           'replace a qualifying Yes' do
          create_disability(
            disability_type: 9,
            disability_response: 1,
            indefinite_and_impairs: 1,
            information_date: current_date - 2.weeks,
          )
          create_disability(
            disability_type: 9,
            disability_response: 1,
            indefinite_and_impairs: later_indefinite_and_impairs,
            information_date: current_date - 1.week,
          )

          expect(resolved_value).to be(true)
        end

        it "does not let a later Yes with IndefiniteAndImpairs #{later_indefinite_and_impairs.inspect} " \
           'replace a No' do
          create_disability(
            disability_type: 9,
            disability_response: 0,
            information_date: current_date - 2.weeks,
          )
          create_disability(
            disability_type: 9,
            disability_response: 1,
            indefinite_and_impairs: later_indefinite_and_impairs,
            information_date: current_date - 1.week,
          )

          expect(resolved_value).to be(false)
        end
      end

      it 'lets a later No replace a Yes with an unanswered IndefiniteAndImpairs' do
        create_disability(
          disability_type: 9,
          disability_response: 1,
          indefinite_and_impairs: 1,
          information_date: current_date - 3.weeks,
        )
        create_disability(
          disability_type: 9,
          disability_response: 1,
          indefinite_and_impairs: nil,
          information_date: current_date - 2.weeks,
        )
        create_disability(
          disability_type: 9,
          disability_response: 0,
          information_date: current_date - 1.week,
        )

        expect(resolved_value).to be(false)
      end

      it 'lets a later qualifying Yes replace a non-qualifying Yes' do
        create_disability(
          disability_type: 9,
          disability_response: 1,
          indefinite_and_impairs: 0,
          information_date: current_date - 2.weeks,
        )
        create_disability(
          disability_type: 9,
          disability_response: 1,
          indefinite_and_impairs: 1,
          information_date: current_date - 1.week,
        )

        expect(resolved_value).to be(true)
      end

      it 'lets a qualifying row win a same-day tie with a non-qualifying row' do
        create_disability(
          disability_type: 9,
          disability_response: 1,
          indefinite_and_impairs: 1,
          information_date: current_date - 1.week,
          date_updated: current_date - 1.week,
        )
        create_disability(
          disability_type: 9,
          disability_response: 1,
          indefinite_and_impairs: 0,
          information_date: current_date - 1.week,
          date_updated: current_date - 1.day,
        )

        expect(resolved_value).to be(true)
      end
    end

    describe 'combining with the enrollment flag' do
      it 'resolves 3.08 No plus a qualifying disability to true' do
        enrollment.update!(DisablingCondition: 0)
        create_disability(
          disability_type: 9,
          disability_response: 1,
          indefinite_and_impairs: 1,
          information_date: current_date - 1.week,
        )

        expect(resolved_value).to be(true)
      end

      it 'resolves 3.08 No plus a non-qualifying Yes to false' do
        enrollment.update!(DisablingCondition: 0)
        create_disability(
          disability_type: 9,
          disability_response: 1,
          indefinite_and_impairs: 0,
          information_date: current_date - 1.week,
        )

        expect(resolved_value).to be(false)
      end

      it 'resolves 3.08 Yes with no disability rows to true' do
        enrollment.update!(DisablingCondition: 1)

        expect(resolved_value).to be(true)
      end

      it 'resolves only No disability rows and no 3.08 answer to false' do
        create_disability(disability_type: 5, disability_response: 0, information_date: current_date - 1.week)
        create_disability(disability_type: 6, disability_response: 0, information_date: current_date - 1.week)

        expect(resolved_value).to be(false)
      end

      it 'resolves only 8/9/99 disability rows and no 3.08 answer to nil' do
        [8, 9, 99].each do |response|
          create_disability(disability_type: 6, disability_response: response, information_date: current_date - 1.week)
        end

        expect(resolved_value).to be_nil
      end
    end
  end

  describe 'disabling_condition vs any_reported_disability' do
    include_context 'with disabling condition helpers'

    let(:hud_field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::DISABLING_CONDITION }
    let(:broad_field) { Hmis::Ce::Match::Expression::PsdeFieldRegistry::ANY_REPORTED_DISABILITY }

    def resolved_values
      {
        hud: resolver.call(clients, hud_field).fetch(destination_client.id),
        broad: resolver.call(clients, broad_field).fetch(destination_client.id),
      }
    end

    # Each case lists the client's disability rows (type, response, IndefiniteAndImpairs, weeks ago),
    # an optional 3.08 answer, and the expected value of each field.
    [
      {
        name: 'short-term physical disability (broken leg)',
        rows: [[5, 1, 0, 1]],
        expected: { hud: false, broad: true },
      },
      {
        name: 'mental health Yes with IndefiniteAndImpairs not collected',
        rows: [[9, 1, 99, 1]],
        expected: { hud: nil, broad: true },
      },
      {
        name: 'qualifying Yes followed by a later Yes with IndefiniteAndImpairs not collected',
        rows: [[9, 1, 1, 2], [9, 1, nil, 1]],
        expected: { hud: true, broad: true },
      },
      {
        name: 'qualifying Yes replaced by a later non-qualifying Yes',
        rows: [[7, 1, 1, 2], [7, 1, 0, 1]],
        expected: { hud: false, broad: true },
      },
      {
        name: 'long-term, impairing chronic health condition',
        rows: [[7, 1, 1, 1]],
        expected: { hud: true, broad: true },
      },
      {
        name: 'HIV/AIDS Yes',
        rows: [[8, 1, nil, 1]],
        expected: { hud: true, broad: true },
      },
      {
        name: 'Yes replaced by a later No',
        rows: [[5, 1, 1, 2], [5, 0, nil, 1]],
        expected: { hud: false, broad: false },
      },
      {
        name: '3.08 Yes with a non-qualifying disability',
        disabling_condition: 1,
        rows: [[5, 1, 0, 1]],
        expected: { hud: true, broad: true },
      },
      {
        name: 'no meaningful data',
        rows: [[5, 9, nil, 1]],
        expected: { hud: nil, broad: nil },
      },
    ].each do |example|
      it "resolves #{example[:name]} to #{example[:expected]}" do
        enrollment.update!(DisablingCondition: example[:disabling_condition]) if example[:disabling_condition]
        example[:rows].each do |(type, response, indefinite_and_impairs, weeks_ago)|
          create_disability(
            disability_type: type,
            disability_response: response,
            indefinite_and_impairs: indefinite_and_impairs,
            information_date: current_date - weeks_ago.weeks,
          )
        end

        expect(resolved_values).to eq(example[:expected])
      end
    end
  end
end
