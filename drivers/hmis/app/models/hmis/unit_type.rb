###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class UnitType < HmisBase
    has_many :external_referral_requests, class_name: 'HmisExternalApis::ReferralRequest', dependent: :restrict_with_exception
    # has_many :external_referral_postings, class_name: 'HmisExternalApis::ReferralPosting', dependent: :restrict_with_exception

    # https://docs.google.com/spreadsheets/d/1xuXIohyPguAw10KcqlqiF23qgbNzKvAR/edit#gid=844425140
    enum(
      bed_type: {
        bed_room_0: 22,
        bed_room_0_accessible: 24,
        bed_room_0_chronic_homeless: 23,
        bed_room_1: 8,
        bed_room_1_accessible: 10,
        bed_room_1_chronic_homeless: 9,
        bed_room_2: 20,
        bed_room_2_accessible: 21,
        bed_room_2_chronic_homeless: 19,
        bed_room_3: 16,
        bed_room_3_accessible: 18,
        bed_room_3_chronic_homeless: 17,
        bed_room_4: 4,
        bed_room_4_accessible: 6,
        bed_room_4_chronic_homeless: 5,
        plus_bed_5_plus_room: 2,
        plus_bed_5_plus_room_accessible: 1,
        plus_bed_5_plus_room_chronic_homeless: 3,
        households_with_children: 31,
        households_without_children: 32,
        mass_shelter_accessible: 26,
        mass_shelter_family: 25,
        mass_shelter_single: 7,
        rapid_re_housing: 11,
        sro: 13,
        sro_accessible: 15,
        sro_chronic_homeless: 14,
        case_management: 30,
        prevention: 27,
        rental_assistance: 12,
        street_outreach_capacity: 29,
        supportive_service_only_capacity: 28,
      },
    )
  end
end
