require 'rails_helper'

RSpec.describe GrdaWarehouse::HudChronic, type: :model do

  let(:client) { create :grda_warehouse_hud_client }

  let(:not_chronic) {
    create :grda_warehouse_hud_enrollment,
      DateToStreetESSH: april_1_2016 - 6.months,
      DisablingCondition: 1 
  }

  let(:enrollment_12_months_homeless) { 
    create :grda_warehouse_hud_enrollment,
      DateToStreetESSH: april_1_2016 - 13.months,
      DisablingCondition: 1 
  }

  let(:enrollment_11_months_homeless) { 
    create :grda_warehouse_hud_enrollment,
      DateToStreetESSH: april_1_2016 - 10.months,
      DisablingCondition: 1,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 112
  }

  let(:enrollment_12_months_on_street) { 
    create :grda_warehouse_hud_enrollment,
      DateToStreetESSH: april_1_2016 - 10.months,
      DisablingCondition: 1,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 111
  }

  let(:service_history) {
    create :grda_warehouse_service_history,
    first_date_in_program: april_1_2016 - 1.month,
    client_id: client.id,
    date: april_1_2016 - 1.month,
    record_type: 'entry',
    computed_project_type: 1
  }
  let(:april_1_2016) { Date.new(2016,4,1) }
  
  context 'if homeless but not chronic' do
    before(:each) do

      # add enrollment
      service_history
      client.enrollments << not_chronic
      @is_chronic = client.hud_chronic? on_date: april_1_2016
    end

    it 'is not hud chronic' do
      expect( @is_chronic ).to be_falsey
    end
  end

  context 'if homeless all of last 12 months' do

    before(:each) do

      # add enrollment
      service_history
      client.enrollments << enrollment_12_months_homeless

      # return client as head of household
      expect_any_instance_of( GrdaWarehouse::ServiceHistory ).to receive(:head_of_household).and_return( client )

      # fake out the source_enrollments so client is disabled.
      source_enrollments = double('source_enrollments')
      expect( client ).to receive(:source_enrollments).and_return(source_enrollments)
      expect( source_enrollments ).to receive(:pluck).with(:DisablingCondition).and_return [1]

      # return an enrollment that has a date to street
      expect_any_instance_of( GrdaWarehouse::ServiceHistory ).to receive(:enrollment).and_return( enrollment_12_months_homeless )
      @is_chronic = client.hud_chronic? on_date: april_1_2016
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
      client.enrollments << enrollment_11_months_homeless

      # return client as head of household
      expect_any_instance_of( GrdaWarehouse::ServiceHistory ).to receive(:head_of_household).and_return( client )

      # fake out the source_enrollments so client is disabled.
      source_enrollments = double('source_enrollments')
      expect( client ).to receive(:source_enrollments).and_return(source_enrollments)
      expect( source_enrollments ).to receive(:pluck).with(:DisablingCondition).and_return [1]
    end

    context 'and 12+ months homeless' do

      before(:each) do
        # return an enrollment that has a date to street
        allow_any_instance_of( GrdaWarehouse::ServiceHistory ).to receive(:enrollment).and_return( enrollment_11_months_homeless )
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
        allow_any_instance_of( GrdaWarehouse::ServiceHistory ).to receive(:enrollment).and_return( enrollment_12_months_on_street )
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
