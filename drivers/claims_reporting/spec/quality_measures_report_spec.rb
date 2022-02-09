###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe ClaimsReporting::QualityMeasuresReport, type: :model do
  it 'can calculate with basic filters' do
    date_range = Date.iso8601('2019-01-01')..Date.iso8601('2019-12-31')

    patients = []

    # EMR data
    aco = Health::AccountableCareOrganization.create!(
      name: 'QualityMeasuresReport Test',
      short_name: 'QMTEST',
      edi_name: '',
    )
    wrong_aco = Health::AccountableCareOrganization.create!(
      name: 'QualityMeasuresReport 2 Test',
      short_name: 'QMTEST2',
      edi_name: '',
    )
    # match - single race
    patients << create(:patient,
                       medicaid_id: 'QMTEST000001',
                       birthdate: date_range.min - 41.years,
                       client: create(:hud_client,
                                      Gender: 2, Ethnicity: 1, AmIndAKNative: 0, Asian: 1, BlackAfAmerican: 1, NativeHIPacific: 0, White: 0, RaceNone: 0),
                       patient_referral: create(:patient_referral, accountable_care_organization_id: aco.id))
    # match - MultiRacial
    patients << create(:patient,
                       medicaid_id: 'QMTEST000002',
                       birthdate: date_range.min - 41.years,
                       client: create(:hud_client,
                                      Gender: 3, Ethnicity: 8, AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 1, White: 0, RaceNone: 0),
                       patient_referral: create(:patient_referral, accountable_care_organization_id: aco.id))
    # wrong race
    patients << create(:patient,
                       medicaid_id: 'QMTEST000003',
                       birthdate: date_range.min - 41.years,
                       client: create(:hud_client,
                                      Gender: 2, Ethnicity: 1, AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 0, White: 1, RaceNone: 0),
                       patient_referral: create(:patient_referral, accountable_care_organization_id: aco.id))
    # wrong ethnicity
    patients << create(:patient,
                       medicaid_id: 'QMTEST000004',
                       birthdate: date_range.min - 41.years,
                       client: create(:hud_client,
                                      Gender: 1, Ethnicity: 2, AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 0, White: 0, RaceNone: 1),
                       patient_referral: create(:patient_referral, accountable_care_organization_id: aco.id))
    # wrong age
    patients << create(:patient,
                       medicaid_id: 'QMTEST000005',
                       birthdate: date_range.min - 60.years,
                       client: create(:hud_client,
                                      Gender: 3, Ethnicity: 8, AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 1, White: 0, RaceNone: 0),
                       patient_referral: create(:patient_referral, accountable_care_organization_id: aco.id))
    # wrong aco
    patients << create(:patient,
                       medicaid_id: 'QMTEST000006',
                       birthdate: date_range.min - 41.years,
                       client: create(:hud_client,
                                      Gender: 3, Ethnicity: 8, AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 1, White: 0, RaceNone: 0),
                       patient_referral: create(:patient_referral, accountable_care_organization_id: wrong_aco.id))

    # wrong cp_enroll_dt
    wrong_enrollment = create(:patient,
                              medicaid_id: 'QMTEST000007',
                              birthdate: date_range.min - 41.years,
                              client: create(:hud_client,
                                             Gender: 2, Ethnicity: 1, AmIndAKNative: 0, Asian: 1, BlackAfAmerican: 1, NativeHIPacific: 0, White: 0, RaceNone: 0),
                              patient_referral: create(:patient_referral, accountable_care_organization_id: aco.id))
    patients << wrong_enrollment

    # Claims data
    patients.each do |p|
      # We read the DOB from the MemberRoster  table so copy the patients birthdate there
      ClaimsReporting::MemberRoster.create!(
        member_id: p.medicaid_id,
        date_of_birth: p.birthdate,
      )

      # The initial MemberEnrollmentRoster filter looks for records for:
      # > Members assigned to a BH CP on or between September 2nd of the year prior to the
      # > measurement year and September 1st of the measurement year.
      cp_enroll_dt = if p == wrong_enrollment
        (date_range.max << 4) + 2.day # September 2st of the measurement year is too late
      else
        (date_range.min << 4) + 1.day # September 2nd of the year prior
      end
      # puts [p.medicaid_id, cp_enroll_dt]
      ClaimsReporting::MemberEnrollmentRoster.create!(
        member_id: p.medicaid_id,
        span_start_date: date_range.min,
        span_end_date: date_range.max,
        cp_enroll_dt: cp_enroll_dt,
        cp_disenroll_dt: (cp_enroll_dt >> 12),
      ).tap do |enrollment|
        # pp enrollment
      end
    end

    expect(Health::Patient.count).to eq(patients.count)

    report = ClaimsReporting::QualityMeasuresReport.new(
      date_range: date_range,
      filter: Filters::QualityMeasuresFilter.new(
        races: ['NativeHIPacific', 'MultiRacial'],
        ethnicities: ['1', '8'],
        genders: ['2', '3'],
        age_ranges: [:forty_to_forty_nine],
        acos: [aco.id],
      ),
    )

    # puts report.assigned_enrollements_scope.to_sql
    expect(report.assigned_enrollements_scope.pluck(:member_id)).to eq(['QMTEST000001', 'QMTEST000002'])

    data = report.serializable_hash
    expect(data).to be_kind_of(Hash)
    expect(data.keys).to include(:measures)
    expect(data.dig(:measures, :assigned_enrollees, :value)).to be(2)
  end
end
