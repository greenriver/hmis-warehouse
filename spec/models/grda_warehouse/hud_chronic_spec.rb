require 'rails_helper'

RSpec.describe GrdaWarehouse::HudChronic, type: :model do
  # need destination and source client, source enrollment and source disability
  let!(:warehouse_ds) { create :destination_data_source }
  let!(:source_ds) { create :source_data_source }
  let!(:client) { create :grda_warehouse_hud_client, data_source_id: warehouse_ds.id }
  let!(:source_client) do
    create(
      :grda_warehouse_hud_client,
      data_source_id: source_ds.id,
      PersonalID: client.PersonalID,
    )
  end
  let!(:warehouse_client) do
    create(
      :warehouse_client,
      destination: client,
      source: source_client,
      data_source_id: source_client.data_source_id,
    )
  end
  let!(:project) do
    create(
      :grda_warehouse_hud_project,
      ProjectType: 1,
      data_source_id: source_ds.id,
    )
  end
  let!(:source_enrollment) do
    create(
      :hud_enrollment,
      EnrollmentID: 'a',
      ProjectID: project.ProjectID,
      EntryDate: Date.new(2014, 4, 1),
      DisablingCondition: 1,
      data_source_id: source_client.data_source_id,
      PersonalID: source_client.PersonalID,
    )
  end
  let!(:source_disability) do
    create(
      :hud_disability,
      EnrollmentID: source_enrollment.EnrollmentID,
      InformationDate: Date.new(2014, 4, 1),
      data_source_id: source_client.data_source_id,
      PersonalID: source_client.PersonalID,
      DisabilityType: 5,
      DisabilityResponse: 1,
      IndefiniteAndImpairs: 1,
    )
  end

  # The following should be associated with the client before each test
  # so that we only instantiate the correct one for the test
  let!(:not_chronic) do
    create(
      :grda_warehouse_hud_enrollment,
      EntryDate: Date.new(2014, 4, 1),
      ProjectID: project.ProjectID,
      DateToStreetESSH: april_1_2016 - 6.months,
      DisablingCondition: 1,
      PersonalID: 'OTHER',
      data_source_id: source_client.data_source_id,
    )
  end

  let!(:enrollment_12_months_homeless) do
    create(
      :grda_warehouse_hud_enrollment,
      EntryDate: Date.new(2014, 4, 1),
      ProjectID: project.ProjectID,
      DateToStreetESSH: april_1_2016 - 13.months,
      DisablingCondition: 1,
      PersonalID: 'OTHER',
      data_source_id: source_client.data_source_id,
    )
  end

  let!(:enrollment_11_months_homeless) do
    create(
      :grda_warehouse_hud_enrollment,
      EntryDate: Date.new(2014, 4, 1),
      ProjectID: project.ProjectID,
      DateToStreetESSH: april_1_2016 - 10.months,
      DisablingCondition: 1,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 112,
      PersonalID: 'OTHER',
      data_source_id: source_client.data_source_id,
    )
  end

  let!(:enrollment_12_months_on_street) do
    create(
      :grda_warehouse_hud_enrollment,
      EntryDate: Date.new(2014, 4, 1),
      ProjectID: project.ProjectID,
      DateToStreetESSH: april_1_2016 - 10.months,
      DisablingCondition: 1,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 111,
      PersonalID: 'OTHER',
      data_source_id: source_client.data_source_id,
    )
  end
  let(:april_1_2016) { Date.new(2016, 4, 1) }

  context 'if homeless but not chronic' do
    it 'is not hud chronic' do
      expect(client.hud_chronic?(on_date: april_1_2016)).to be_falsey
    end
  end

  context 'if homeless all of last 12 months' do
    before(:each) do
      # force the chronic calculation, which sets the triggers
      Rails.cache.delete('chronically_disabled_clients')
      enrollment_12_months_homeless.update(PersonalID: source_client.PersonalID)
      @is_chronic = client.hud_chronic?(on_date: april_1_2016)
    end

    it 'is HUD chronic' do
      expect(@is_chronic).to be true
    end
    it 'has correct trigger' do
      expect(client.hud_chronic_data[:trigger]).to eq 'All 12 of the last 12 months homeless'
    end
  end

  context 'when 4+ episodes of homelessness in last 3 years' do
    context 'and 12+ months homeless' do
      before(:each) do
        Rails.cache.delete('chronically_disabled_clients')
        enrollment_11_months_homeless.update(PersonalID: source_client.PersonalID)
        @is_chronic = client.hud_chronic? on_date: april_1_2016
      end

      it 'is HUD chronic' do
        expect(@is_chronic).to be true
      end
      it 'has correct trigger' do
        expect(client.hud_chronic_data[:trigger]).to eq 'Four or more episodes of homelessness in the past three years and 12+ months homeless'
      end
    end

    context 'and 12+ months on the street or in ES/SH' do
      before(:each) do
        Rails.cache.delete('chronically_disabled_clients')
        # return an enrollment that has a date to street
        enrollment_12_months_on_street.update(PersonalID: source_client.PersonalID)
        @is_chronic = client.hud_chronic? on_date: april_1_2016
      end

      it 'is HUD chronic' do
        expect(@is_chronic).to be true
      end
      it 'has correct trigger' do
        expect(client.hud_chronic_data[:trigger]).to eq 'Four or more episodes of homelessness in the past three years and 12+ month on the street or in ES or SH'
      end
    end
  end
end
