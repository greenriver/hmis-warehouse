require 'rails_helper'

RSpec.describe GrdaWarehouse::HudChronic, type: :model do

  # need destination and source client, source enrollment and source disability
  let!(:client) { create :grda_warehouse_hud_client }
  let!(:ds) { create :data_source_fixed_id }
  let!(:source_client) {
    create :grda_warehouse_hud_client,
    data_source: ds,
    PersonalID: client.PersonalID
  }
  let!(:warehouse_client) {
    create :warehouse_client,
    destination: client,
    source: source_client,
    data_source_id: source_client.data_source_id
  }
  let!(:source_enrollment) {
    create :hud_enrollment,
    DisablingCondition: 1,
    data_source_id: source_client.data_source_id,
    PersonalID: source_client.PersonalID
  }
  let!(:source_disability) {
    create :hud_disability,
    EnrollmentID: source_enrollment.EnrollmentID,
    data_source_id: source_client.data_source_id,
    PersonalID: source_client.PersonalID,
    DisabilityType: 5,
    DisabilityResponse: 1
  }

  # The following should be called to instantiate them in before each
  # so that we only instantiate the correct one for the test
  let(:not_chronic) {
    create :grda_warehouse_hud_enrollment,
      ProjectID: 1,
      DateToStreetESSH: april_1_2016 - 6.months,
      DisablingCondition: 1,
      PersonalID: source_client.PersonalID,
      data_source_id: source_client.data_source_id
  }

  let(:enrollment_12_months_homeless) {
    create :grda_warehouse_hud_enrollment,
      ProjectID: 1,
      DateToStreetESSH: april_1_2016 - 13.months,
      DisablingCondition: 1,
      PersonalID: source_client.PersonalID,
      data_source_id: source_client.data_source_id
  }

  let(:enrollment_11_months_homeless) {
    create :grda_warehouse_hud_enrollment,
      ProjectID: 1,
      DateToStreetESSH: april_1_2016 - 10.months,
      DisablingCondition: 1,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 112,
      PersonalID: source_client.PersonalID,
      data_source_id: source_client.data_source_id
  }

  let(:enrollment_12_months_on_street) {
    create :grda_warehouse_hud_enrollment,
      ProjectID: 1,
      DateToStreetESSH: april_1_2016 - 10.months,
      DisablingCondition: 1,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 111,
      PersonalID: source_client.PersonalID,
      data_source_id: source_client.data_source_id
  }

  let(:service_history) {
    create :grda_warehouse_service_history,
    first_date_in_program: april_1_2016 - 1.month,
    client_id: client.id,
    date: april_1_2016 - 1.month,
    record_type: :entry,
    computed_project_type: 1,
    head_of_household_id: source_client.PersonalID,
    data_source_id: source_client.data_source_id,
    project_id: 1
  }
  let(:april_1_2016) { Date.new(2016,4,1) }

  context 'if homeless but not chronic' do
    before(:each) do
      # Instantiate the appropriate history
      service_history
      not_chronic
    end

    it 'is not hud chronic' do
      expect( client.hud_chronic?(on_date: april_1_2016) ).to be_falsey
    end
  end

  context 'if homeless all of last 12 months' do

    before(:each) do
      # add enrollment
      service_history
      enrollment_12_months_homeless

      # force the chronic calculation, which sets the triggers
      @is_chronic = client.hud_chronic?(on_date: april_1_2016)
    end

    it 'is HUD chronic' do
      expect( @is_chronic ).to be true
    end
    it 'has correct trigger' do
      expect( client.hud_chronic_data[:trigger] ).to eq "All 12 of the last 12 months homeless"
    end
  end

  context 'when 4+ episodes of homelessness in last 3 years' do

    before(:each) do
      # add enrollment
      service_history
      enrollment_11_months_homeless
    end

    context 'and 12+ months homeless' do

      before(:each) do
        service_history.update(enrollment_group_id: enrollment_11_months_homeless.EnrollmentID)
        @is_chronic = client.hud_chronic? on_date: april_1_2016
      end

      it 'is HUD chronic' do
        expect( @is_chronic ).to be true
      end
      it 'has correct trigger' do
        expect( client.hud_chronic_data[:trigger] ).to eq 'Four or more episodes of homelessness in the past three years and 12+ months homeless'
      end
    end

    context 'and 12+ months on the street or in ES/SH' do

      before(:each) do
        # return an enrollment that has a date to street
        service_history.update!(enrollment_group_id: enrollment_12_months_on_street.EnrollmentID)
        puts client.service_history_enrollments.hud_homeless(chronic_types_only: true).entry.ongoing(on_date: april_1_2016).order(first_date_in_program: :desc).first&.enrollment&.inspect
        @is_chronic = client.hud_chronic? on_date: april_1_2016
      end

      it 'is HUD chronic' do
        expect( @is_chronic ).to be true
      end
      it 'has correct trigger' do
        expect( client.hud_chronic_data[:trigger] ).to eq 'Four or more episodes of homelessness in the past three years and 12+ month on the street or in ES or SH'
      end
    end
  end

end
