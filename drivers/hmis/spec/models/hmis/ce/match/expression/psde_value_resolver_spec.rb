# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::PsdeValueResolver, type: :model do
  registry = Hmis::Ce::Match::Expression::PsdeFieldRegistry

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

  # Attributes for a HUD row recorded on +enrollment+, for the enrollment's own client and data source.
  def row_defaults(enrollment)
    {
      enrollment: enrollment,
      client: enrollment.client,
      data_source: enrollment.data_source,
      data_collection_stage: 1,
    }
  end

  def create_disability(for_enrollment: enrollment, **attrs)
    create(:hmis_disability, :skip_validate, row_defaults(for_enrollment).merge(attrs))
  end

  def create_health_and_dv(for_enrollment: enrollment, **attrs)
    create(:hmis_health_and_dv, :skip_validate, row_defaults(for_enrollment).merge(attrs))
  end

  def create_income_benefit(for_enrollment: enrollment, **attrs)
    create(:hmis_income_benefit, :skip_validate, row_defaults(for_enrollment).merge(attrs))
  end

  def create_enrollment(**attrs)
    defaults = {
      data_source: hmis_data_source,
      client: client,
      EntryDate: current_date - 1.month,
    }
    create(:hmis_hud_enrollment, defaults.merge(attrs))
  end

  def configure_project_group(projects)
    project_group = create(:hmis_project_group, data_source: hmis_data_source, with_projects: projects)
    AppConfigProperty.create!(key: 'hmis_ce/eligibility_project_group_id', value: project_group.id)
  end

  def resolved_value
    resolver.call(clients, field).fetch(destination_client.id)
  end

  # Including contexts provide `field` and `create_response(response, **attrs)`, which records a raw HUD
  # response for the field on the client's open enrollment.
  shared_examples 'a latest Yes/No field' do
    it 'returns nil when there are no rows in scope' do
      expect(resolver.call(clients, field)).to eq({ destination_client.id => nil })
    end

    it 'resolves Yes (1) to true' do
      create_response(1, information_date: current_date - 1.week)

      expect(resolved_value).to be(true)
    end

    it 'resolves No (0) to false' do
      create_response(0, information_date: current_date - 1.week)

      expect(resolved_value).to be(false)
    end

    it 'returns nil when only 8/9/99/nil responses exist' do
      [8, 9, 99, nil].each_with_index do |response, i|
        create_response(response, information_date: current_date - (i + 1).days)
      end

      expect(resolved_value).to be_nil
    end

    it 'skips a later 8/9/99/nil response and uses the prior Yes/No' do
      create_response(1, information_date: current_date - 2.weeks)
      create_response(99, information_date: current_date - 1.week)

      expect(resolved_value).to be(true)
    end

    it 'uses the latest InformationDate, regardless of insertion order or DateUpdated' do
      create_response(1, information_date: current_date - 1.week, date_updated: current_date - 2.weeks)
      create_response(0, information_date: current_date - 2.weeks, date_updated: current_date - 1.week)

      expect(resolved_value).to be(true)
    end
  end

  shared_examples 'a values-in-window Yes/No field' do
    it 'returns an empty array when there are no rows in scope' do
      expect(resolver.call(clients, field)).to eq({ destination_client.id => [] })
    end

    it 'returns every Yes/No value by InformationDate, newest first, deduplicated, without 8/9/99/nil' do
      # The newest row is created first, so insertion order disagrees with InformationDate order
      create_response(0, information_date: current_date - 1.week)
      create_response(1, information_date: current_date - 3.weeks)
      create_response(1, information_date: current_date - 2.weeks)
      create_response(99, information_date: current_date - 1.day)
      create_response(nil, information_date: current_date - 2.days)

      expect(resolver.call(clients, field)).to eq({ destination_client.id => [false, true] })
    end
  end

  describe 'disability fields' do
    {
      'physical_disability' => 5,
      'developmental_disability' => 6,
      'chronic_health_condition' => 7,
      'hiv_aids' => 8,
      'mental_health_disorder' => 9,
      'substance_use_disorder' => 10,
    }.each do |key, disability_type|
      describe key do
        def create_response(response, **attrs)
          create_disability(disability_type: disability_type, disability_response: response, **attrs)
        end

        let(:disability_type) { disability_type }

        describe 'most recent' do
          let(:field) { registry[key] }

          it_behaves_like 'a latest Yes/No field'
        end

        describe 'all values in window' do
          let(:field) { registry["#{key}#{registry::VALUES_IN_WINDOW_SUFFIX}"] }

          it_behaves_like 'a values-in-window Yes/No field'
        end
      end
    end

    describe 'substance use response codes' do
      [2, 3].each do |code|
        it "resolves Drug/Both (#{code}) to true" do
          create_disability(disability_type: 10, disability_response: code, information_date: current_date - 1.week)

          expect(resolver.call(clients, registry::SUBSTANCE_USE_DISORDER)).to eq({ destination_client.id => true })
        end
      end

      it 'includes Drug (2) as true in the values in window' do
        create_disability(disability_type: 10, disability_response: 2, information_date: current_date - 1.week)

        expect(resolver.call(clients, registry::SUBSTANCE_USE_DISORDER_VALUES_IN_WINDOW)).
          to eq({ destination_client.id => [true] })
      end
    end

    # Substance use codes (2/3) are not valid for other types. Note this is stricter than the CAS
    # path (GrdaWarehouse::Hud::Client#<type>_response), which accepts 0/1/2/3 for every type.
    it 'ignores substance use codes on other disability types' do
      create_disability(disability_type: 9, disability_response: 2, information_date: current_date - 1.week)

      expect(resolver.call(clients, registry::MENTAL_HEALTH_DISORDER)).to eq({ destination_client.id => nil })
    end

    it 'resolves each disability type from its own rows' do
      create_disability(disability_type: 9, disability_response: 1, information_date: current_date - 1.week)
      create_disability(disability_type: 5, disability_response: 0, information_date: current_date - 3.days)

      expect(resolver.call(clients, registry::MENTAL_HEALTH_DISORDER)).to eq({ destination_client.id => true })
      expect(resolver.call(clients, registry::PHYSICAL_DISABILITY)).to eq({ destination_client.id => false })
    end
  end

  describe 'domestic_violence_survivor' do
    def create_response(response, **attrs)
      create_health_and_dv(domestic_violence_survivor: response, **attrs)
    end

    describe 'most recent' do
      let(:field) { registry::DOMESTIC_VIOLENCE_SURVIVOR }

      it_behaves_like 'a latest Yes/No field'
    end

    describe 'all values in window' do
      let(:field) { registry::DOMESTIC_VIOLENCE_SURVIVOR_VALUES_IN_WINDOW }

      it_behaves_like 'a values-in-window Yes/No field'
    end
  end

  describe 'total_monthly_income' do
    let(:field) { registry::TOTAL_MONTHLY_INCOME }

    it 'returns nil for clients with no income benefits in scope' do
      expect(resolver.call(clients, field)).to eq({ destination_client.id => nil })
    end

    it 'returns nil when the only row has a refused IncomeFromAnySource' do
      create_income_benefit(
        information_date: current_date - 1.week,
        income_from_any_source: 9,
        total_monthly_income: '500',
      )

      expect(resolved_value).to be_nil
    end

    it 'resolves 0 when the latest valid row is IncomeFromAnySource No after Yes/$500' do
      create_income_benefit(
        information_date: current_date - 2.weeks,
        income_from_any_source: 1,
        total_monthly_income: '500',
      )
      create_income_benefit(
        information_date: current_date - 1.week,
        income_from_any_source: 0,
        total_monthly_income: nil,
      )

      expect(resolved_value).to eq(0)
    end

    it 'skips a later refused row and uses the prior Yes/$500' do
      create_income_benefit(
        information_date: current_date - 2.weeks,
        income_from_any_source: 1,
        total_monthly_income: '500',
      )
      create_income_benefit(
        information_date: current_date - 1.week,
        income_from_any_source: 9,
        total_monthly_income: nil,
      )

      expect(resolved_value).to eq(500.0)
    end

    it 'skips a later Yes with no TotalMonthlyIncome as invalid and uses the prior Yes/$500' do
      create_income_benefit(
        information_date: current_date - 2.weeks,
        income_from_any_source: 1,
        total_monthly_income: '500',
      )
      create_income_benefit(
        information_date: current_date - 1.week,
        income_from_any_source: 1,
        total_monthly_income: nil,
      )

      expect(resolved_value).to eq(500.0)
    end

    it 'resolves 0 for the Yes/$0 data quality edge case' do
      create_income_benefit(
        information_date: current_date - 1.week,
        income_from_any_source: 1,
        total_monthly_income: '0',
      )

      expect(resolved_value).to eq(0)
    end

    it 'uses the latest InformationDate, regardless of insertion order or DateUpdated' do
      create_income_benefit(
        information_date: current_date - 1.week,
        income_from_any_source: 1,
        total_monthly_income: '200',
        date_updated: current_date - 2.weeks,
      )
      create_income_benefit(
        information_date: current_date - 2.weeks,
        income_from_any_source: 1,
        total_monthly_income: '100',
        date_updated: current_date - 1.week,
      )

      expect(resolved_value).to eq(200.0)
    end
  end

  # Row selection and scoping shared by every HUD table field above, checked through one field.
  describe 'row selection for HUD table fields' do
    let(:field) { registry::MENTAL_HEALTH_DISORDER }

    def create_mental_health(response, **attrs)
      create_disability(disability_type: 9, disability_response: response, **attrs)
    end

    describe 'ordering' do
      let(:shared_date) { current_date - 1.week }

      it 'breaks InformationDate ties by the latest DateUpdated, not the highest id' do
        create_mental_health(1, information_date: shared_date, date_updated: current_date - 1.day)
        create_mental_health(0, information_date: shared_date, date_updated: current_date - 1.week)

        expect(resolved_value).to be(true)
      end

      it 'breaks InformationDate and DateUpdated ties by the highest id' do
        create_mental_health(1, information_date: shared_date, date_updated: shared_date)
        create_mental_health(0, information_date: shared_date, date_updated: shared_date)

        expect(resolved_value).to be(false)
      end

      it 'does not let a null DateUpdated win the tiebreak' do
        create_mental_health(1, information_date: shared_date, date_updated: shared_date)
        without_date = create_mental_health(0, information_date: shared_date)
        without_date.update_columns(DateUpdated: nil)

        expect(resolved_value).to be(true)
      end

      it 'ignores rows without an InformationDate' do
        create_mental_health(1, information_date: current_date - 1.week)
        create_mental_health(0, information_date: nil)

        expect(resolved_value).to be(true)
      end
    end

    describe 'eligibility scope' do
      it 'excludes rows from exited enrollments when lookback is 0' do
        exited_enrollment = create_enrollment(EntryDate: current_date - 3.months, exit_date: current_date - 1.month)
        create_mental_health(1, for_enrollment: exited_enrollment, information_date: current_date - 6.weeks)

        expect(resolved_value).to be_nil
      end

      it 'excludes rows from projects outside the configured project group' do
        in_group_project = create(:hmis_hud_project, data_source: hmis_data_source)
        configure_project_group([in_group_project])
        create_mental_health(1, information_date: current_date - 1.week)

        expect(resolved_value).to be_nil
      end

      it 'uses the latest row across merged source clients' do
        other_source_client = create(:hmis_hud_client, data_source: hmis_data_source)
        create(:hmis_warehouse_client, data_source: hmis_data_source, source: other_source_client, destination: destination_client)
        other_enrollment = create_enrollment(client: other_source_client)
        create_mental_health(1, for_enrollment: other_enrollment, information_date: current_date - 1.week)
        create_mental_health(0, information_date: current_date - 2.weeks)

        expect(resolved_value).to be(true)
      end

      it 'includes rows from a non-HMIS source data source linked to the destination client' do
        non_hmis_data_source = create(:source_data_source)
        non_hmis_client = create(:hmis_hud_client, data_source: non_hmis_data_source)
        create(:hmis_warehouse_client, data_source: non_hmis_data_source, source: non_hmis_client, destination: destination_client)
        non_hmis_enrollment = create_enrollment(data_source: non_hmis_data_source, client: non_hmis_client)
        create_mental_health(1, for_enrollment: non_hmis_enrollment, information_date: current_date - 1.week)

        expect(resolved_value).to be(true)
      end

      it 'collects values in window across enrollments' do
        older_enrollment = create_enrollment(EntryDate: current_date - 2.months)
        create_mental_health(1, for_enrollment: older_enrollment, information_date: current_date - 3.weeks)
        create_mental_health(0, information_date: current_date - 1.week)

        values_by_client = resolver.call(clients, registry::MENTAL_HEALTH_DISORDER_VALUES_IN_WINDOW)

        expect(values_by_client).to eq({ destination_client.id => [false, true] })
      end
    end
  end

  # Each test resolves a batch of three requested clients: this one, one with different data, and one with no
  # data. A fourth client has data but is not requested, and must not appear in the result.
  describe 'batch resolution' do
    def create_client_enrollment
      source_client = create(:hmis_hud_client_with_warehouse_client, data_source: hmis_data_source)
      create_enrollment(client: source_client)
    end

    let!(:other_enrollment) { create_client_enrollment }
    let!(:no_data_enrollment) { create_client_enrollment }
    let!(:unrequested_enrollment) { create_client_enrollment }

    let(:other_id) { other_enrollment.client.destination_client.id }
    let(:no_data_id) { no_data_enrollment.client.destination_client.id }
    let(:batch) { GrdaWarehouse::Hud::Client.where(id: [destination_client.id, other_id, no_data_id]) }

    it 'resolves total_monthly_income per client' do
      create_income_benefit(information_date: current_date - 1.week, income_from_any_source: 1, total_monthly_income: '100')
      create_income_benefit(for_enrollment: other_enrollment, information_date: current_date - 1.week, income_from_any_source: 0)
      create_income_benefit(
        for_enrollment: unrequested_enrollment,
        information_date: current_date - 1.week,
        income_from_any_source: 1,
        total_monthly_income: '999',
      )

      expect(resolver.call(batch, registry::TOTAL_MONTHLY_INCOME)).to eq(
        destination_client.id => 100.0,
        other_id => 0,
        no_data_id => nil,
      )
    end

    it 'resolves a latest Yes/No field per client' do
      create_disability(disability_type: 9, disability_response: 1, information_date: current_date - 1.week)
      create_disability(for_enrollment: other_enrollment, disability_type: 9, disability_response: 0, information_date: current_date - 1.week)
      create_disability(for_enrollment: unrequested_enrollment, disability_type: 9, disability_response: 1, information_date: current_date - 1.week)

      expect(resolver.call(batch, registry::MENTAL_HEALTH_DISORDER)).to eq(
        destination_client.id => true,
        other_id => false,
        no_data_id => nil,
      )
    end

    it 'resolves a values-in-window field per client' do
      create_disability(disability_type: 9, disability_response: 1, information_date: current_date - 2.weeks)
      create_disability(disability_type: 9, disability_response: 0, information_date: current_date - 1.week)
      create_disability(for_enrollment: other_enrollment, disability_type: 9, disability_response: 0, information_date: current_date - 1.week)
      create_disability(for_enrollment: unrequested_enrollment, disability_type: 9, disability_response: 1, information_date: current_date - 1.week)

      expect(resolver.call(batch, registry::MENTAL_HEALTH_DISORDER_VALUES_IN_WINDOW)).to eq(
        destination_client.id => [false, true],
        other_id => [false],
        no_data_id => [],
      )
    end

    [registry::DISABLING_CONDITION, registry::ANY_REPORTED_DISABILITY].each do |disabling_field|
      it "resolves #{disabling_field.key} per client" do
        # This client: Yes from a disability record (rule B)
        create_disability(disability_type: 6, disability_response: 1, information_date: current_date - 1.week)
        # Other client: No from both the enrollment flag (rule A) and a disability record (rule B)
        other_enrollment.update!(DisablingCondition: 0)
        create_disability(for_enrollment: other_enrollment, disability_type: 9, disability_response: 0, information_date: current_date - 1.week)
        # Unrequested client: Yes from both rules
        unrequested_enrollment.update!(DisablingCondition: 1)
        create_disability(for_enrollment: unrequested_enrollment, disability_type: 6, disability_response: 1, information_date: current_date - 1.week)

        expect(resolver.call(batch, disabling_field)).to eq(
          destination_client.id => true,
          other_id => false,
          no_data_id => nil,
        )
      end
    end
  end

  # Both disabling condition fields share one algorithm and differ only in the per-row tests. This block
  # covers the shared algorithm through the broad field; the HUD block below covers the HUD row tests.
  describe 'any_reported_disability' do
    let(:field) { registry::ANY_REPORTED_DISABILITY }

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

      it 'uses the latest EntryDate, regardless of insertion order or DateUpdated' do
        # Created first and updated earlier, but entered later
        enrollment.update_columns(DisablingCondition: 1, DateUpdated: (current_date - 1.week).to_time)
        create_enrollment(DisablingCondition: 0, EntryDate: current_date - 2.months)

        expect(resolved_value).to be(true)
      end

      it 'skips later enrollments answered 8/9/99' do
        enrollment.update!(DisablingCondition: 1)
        [8, 9, 99].each_with_index do |response, i|
          create_enrollment(DisablingCondition: response, EntryDate: current_date - (i + 1).days)
        end

        expect(resolved_value).to be(true)
      end

      it 'breaks EntryDate ties by DateUpdated' do
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
      it 'uses the latest InformationDate per type, regardless of insertion order' do
        create_disability(disability_type: 9, disability_response: 0, information_date: current_date - 1.week)
        create_disability(disability_type: 9, disability_response: 1, information_date: current_date - 2.weeks)

        expect(resolved_value).to be(false)
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

      # Codes 2/3 are only valid for substance use, but the warehouse accepts them for every type
      [2, 3].each do |response|
        it "counts response #{response} as Yes, even on a type other than substance use" do
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
        create_disability(for_enrollment: old_enrollment, disability_type: 9, disability_response: 1, information_date: current_date - 1.year)

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
        create_disability(for_enrollment: in_group_enrollment, disability_type: 9, disability_response: 1, information_date: current_date - 2.weeks)
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
        create_disability(for_enrollment: wip_enrollment, disability_type: 9, disability_response: 1, information_date: current_date - 1.week)

        expect(resolved_value).to be(true)
      end
    end

    describe 'multiple source clients' do
      let(:other_data_source) { create(:source_data_source) }
      let(:other_source_client) { create(:hmis_hud_client, data_source: other_data_source) }
      let(:other_enrollment) { create_enrollment(data_source: other_data_source, client: other_source_client) }

      before do
        create(
          :hmis_warehouse_client,
          data_source: other_data_source,
          source: other_source_client,
          destination: destination_client,
        )
      end

      it 'lets a later No in another data source override a Yes of the same type' do
        create_disability(disability_type: 9, disability_response: 1, information_date: current_date - 2.weeks)
        create_disability(for_enrollment: other_enrollment, disability_type: 9, disability_response: 0, information_date: current_date - 1.week)

        expect(resolved_value).to be(false)
      end

      it 'uses the latest answered enrollment across source clients' do
        enrollment.update!(DisablingCondition: 1)
        other_enrollment.update!(DisablingCondition: 0, EntryDate: current_date - 1.week)

        expect(resolved_value).to be(false)
      end
    end
  end

  describe 'disabling_condition (HUD)' do
    let(:field) { registry::DISABLING_CONDITION }

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
    end

    # An unanswered follow-up is missing data, so the row is not an answer
    [99, nil].each do |indefinite_and_impairs|
      it "resolves Yes with IndefiniteAndImpairs #{indefinite_and_impairs.inspect} to nil" do
        create_disability(
          disability_type: 9,
          disability_response: 1,
          indefinite_and_impairs: indefinite_and_impairs,
          information_date: current_date - 1.week,
        )

        expect(resolved_value).to be_nil
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

      [99, nil].each do |later_indefinite_and_impairs|
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

      it 'resolves only 8/9/99 disability rows and no 3.08 answer to nil' do
        [8, 9, 99].each do |response|
          create_disability(disability_type: 6, disability_response: response, information_date: current_date - 1.week)
        end

        expect(resolved_value).to be_nil
      end
    end
  end

  describe 'disabling_condition vs any_reported_disability' do
    let(:hud_field) { registry::DISABLING_CONDITION }
    let(:broad_field) { registry::ANY_REPORTED_DISABILITY }

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
        name: 'qualifying Yes replaced by a later non-qualifying Yes',
        rows: [[7, 1, 1, 2], [7, 1, 0, 1]],
        expected: { hud: false, broad: true },
      },
      {
        name: '3.08 Yes with a non-qualifying disability',
        disabling_condition: 1,
        rows: [[5, 1, 0, 1]],
        expected: { hud: true, broad: true },
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
