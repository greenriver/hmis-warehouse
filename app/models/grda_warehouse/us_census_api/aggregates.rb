###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Code initially written for and funded by Delaware Health and Social Services.
# Used and modified with permission.
#
# This module provides sets of variables that sum together for various
# stratifications that our app needs. The names of the variables listed here
# are internal names since the actual variable name used by the census is both
# non-semantic and varies between ACS and the regular decennial census

module GrdaWarehouse
  module UsCensusApi
    module Aggregates
      def self.compose(a, b)
        if a.is_a?(Hash)
          if b.is_a?(Hash)
            a.map { |k, v| [k, compose(v, b[k])] }.to_h
          else
            a.map { |k, v| [k, compose(v, b)] }.to_h
          end
        else
          if b.is_a?(Hash)
            b.map { |k, v| [k, compose(a, v)] }.to_h
          else
            a + b
          end
        end
      end

      ALL_PEOPLE         = ['POP::TOTAL']

      #######
      # Age #
      #######

      MALE               = ['POP::MALE']
      MALE_AGE_0_4       = ['POP::MALE::UNDER_5_YEARS']
      MALE_AGE_5_9       = ['POP::MALE::5_TO_9_YEARS']
      MALE_AGE_10_14     = ['POP::MALE::10_TO_14_YEARS']
      MALE_AGE_15_17     = ['POP::MALE::15_TO_17_YEARS']
      MALE_AGE_18_24     = ['POP::MALE::18_AND_19_YEARS', 'POP::MALE::20_YEARS', 'POP::MALE::21_YEARS', 'POP::MALE::22_TO_24_YEARS' ]
      MALE_AGE_25_34     = ['POP::MALE::25_TO_29_YEARS', 'POP::MALE::30_TO_34_YEARS']
      MALE_AGE_35_44     = ['POP::MALE::35_TO_39_YEARS', 'POP::MALE::40_TO_44_YEARS']
      MALE_AGE_45_54     = ['POP::MALE::45_TO_49_YEARS', 'POP::MALE::50_TO_54_YEARS']
      MALE_AGE_55_64     = ['POP::MALE::55_TO_59_YEARS', 'POP::MALE::60_AND_61_YEARS', 'POP::MALE::62_TO_64_YEARS']
      MALE_AGE_65_74     = ['POP::MALE::65_AND_66_YEARS', 'POP::MALE::67_TO_69_YEARS', 'POP::MALE::70_TO_74_YEARS']
      MALE_AGE_75_84     = ['POP::MALE::75_TO_79_YEARS', 'POP::MALE::80_TO_84_YEARS']
      MALE_AGE_85_PLUS   = ['POP::MALE::85_YEARS_AND_OVER']

      FEMALE             = ['POP::FEMALE']
      FEMALE_AGE_0_4     = ['POP::FEMALE::UNDER_5_YEARS']
      FEMALE_AGE_5_9     = ['POP::FEMALE::5_TO_9_YEARS']
      FEMALE_AGE_10_14   = ['POP::FEMALE::10_TO_14_YEARS']
      FEMALE_AGE_15_17   = ['POP::FEMALE::15_TO_17_YEARS']
      FEMALE_AGE_18_24   = ['POP::FEMALE::18_AND_19_YEARS', 'POP::FEMALE::20_YEARS', 'POP::FEMALE::21_YEARS', 'POP::FEMALE::22_TO_24_YEARS']
      FEMALE_AGE_25_34   = ['POP::FEMALE::25_TO_29_YEARS', 'POP::FEMALE::30_TO_34_YEARS']
      FEMALE_AGE_35_44   = ['POP::FEMALE::35_TO_39_YEARS', 'POP::FEMALE::40_TO_44_YEARS']
      FEMALE_AGE_45_54   = ['POP::FEMALE::45_TO_49_YEARS', 'POP::FEMALE::50_TO_54_YEARS']
      FEMALE_AGE_55_64   = ['POP::FEMALE::55_TO_59_YEARS', 'POP::FEMALE::60_AND_61_YEARS', 'POP::FEMALE::62_TO_64_YEARS']
      FEMALE_AGE_65_74   = ['POP::FEMALE::65_AND_66_YEARS', 'POP::FEMALE::67_TO_69_YEARS', 'POP::FEMALE::70_TO_74_YEARS']
      FEMALE_AGE_75_84   = ['POP::FEMALE::75_TO_79_YEARS', 'POP::FEMALE::80_TO_84_YEARS']
      FEMALE_AGE_85_PLUS = ['POP::FEMALE::85_YEARS_AND_OVER']

      AGE_0_4     = MALE_AGE_0_4 + FEMALE_AGE_0_4
      AGE_5_9     = MALE_AGE_5_9 + FEMALE_AGE_5_9
      AGE_10_14   = MALE_AGE_10_14 + FEMALE_AGE_10_14
      AGE_15_17   = MALE_AGE_15_17 + FEMALE_AGE_15_17
      AGE_18_24   = MALE_AGE_18_24 + FEMALE_AGE_18_24
      AGE_25_34   = MALE_AGE_25_34 + FEMALE_AGE_25_34
      AGE_35_44   = MALE_AGE_35_44 + FEMALE_AGE_35_44
      AGE_45_54   = MALE_AGE_45_54 + FEMALE_AGE_45_54
      AGE_55_64   = MALE_AGE_55_64 + FEMALE_AGE_55_64
      AGE_65_74   = MALE_AGE_65_74 + FEMALE_AGE_65_74
      AGE_75_84   = MALE_AGE_75_84 + FEMALE_AGE_75_84
      AGE_85_PLUS = MALE_AGE_85_PLUS + FEMALE_AGE_85_PLUS

      UNDER_18_PEOPLE          = AGE_0_4 + AGE_5_9 + AGE_10_14 + AGE_15_17
      BETWEEN_18_AND_65_PEOPLE = AGE_18_24 + AGE_25_34 + AGE_35_44 + AGE_45_54 + AGE_55_64
      OVER_65_PEOPLE           = AGE_65_74 + AGE_75_84 + AGE_85_PLUS

      #############################
      # Race and Ethnicity BY AGE #
      #############################

      RACE_ETH = ['WHITE', 'BLACK', 'HISPANIC', 'NOT_HISPANIC', 'ASIAN', 'PACIFIC_ISLANDER', 'OTHER_RACE', 'TWO_OR_MORE_RACES', 'NATIVE_AMERICAN' ]

      RACE_ETH.each do |stratum|
        ["MALE", "FEMALE"].each do |sex|
          const_set("#{stratum}_#{sex}_AGE_0_4", ["POP::#{stratum}::#{sex}::UNDER_5_YEARS"])
          const_set("#{stratum}_#{sex}_AGE_5_9", ["POP::#{stratum}::#{sex}::5_TO_9_YEARS"])
          const_set("#{stratum}_#{sex}_AGE_10_14", ["POP::#{stratum}::#{sex}::10_TO_14_YEARS"])
          const_set("#{stratum}_#{sex}_AGE_15_17", ["POP::#{stratum}::#{sex}::15_TO_17_YEARS"])
          const_set("#{stratum}_#{sex}_AGE_18_24", {
            sf1: ["POP::#{stratum}::#{sex}::18_AND_19_YEARS", "POP::#{stratum}::#{sex}::20_YEARS", "POP::#{stratum}::#{sex}::21_YEARS", "POP::#{stratum}::#{sex}::22_TO_24_YEARS"],
            acs: ["POP::#{stratum}::#{sex}::18_AND_19_YEARS", "POP::#{stratum}::#{sex}::20_TO_24_YEARS"]
          })
          const_set("#{stratum}_#{sex}_AGE_25_34", ["POP::#{stratum}::#{sex}::25_TO_29_YEARS", "POP::#{stratum}::#{sex}::30_TO_34_YEARS"])
          const_set("#{stratum}_#{sex}_AGE_35_44", {
            sf1: ["POP::#{stratum}::#{sex}::35_TO_39_YEARS", "POP::#{stratum}::#{sex}::40_TO_44_YEARS"],
            acs: ["POP::#{stratum}::#{sex}::35_TO_44_YEARS"]
          })
          const_set("#{stratum}_#{sex}_AGE_45_54", {
            sf1: ["POP::#{stratum}::#{sex}::45_TO_49_YEARS", "POP::#{stratum}::#{sex}::50_TO_54_YEARS"],
            acs: ["POP::#{stratum}::#{sex}::45_TO_54_YEARS"]
          })
          const_set("#{stratum}_#{sex}_AGE_55_64", {
            sf1: ["POP::#{stratum}::#{sex}::55_TO_59_YEARS", "POP::#{stratum}::#{sex}::60_AND_61_YEARS", "POP::#{stratum}::#{sex}::62_TO_64_YEARS"],
            acs: ["POP::#{stratum}::#{sex}::55_TO_64_YEARS"]
          })
          const_set("#{stratum}_#{sex}_AGE_65_74", {
            sf1: ["POP::#{stratum}::#{sex}::65_AND_66_YEARS", "POP::#{stratum}::#{sex}::67_TO_69_YEARS", "POP::#{stratum}::#{sex}::70_TO_74_YEARS"],
            acs: ["POP::#{stratum}::#{sex}::65_TO_74_YEARS"]
          })
          const_set("#{stratum}_#{sex}_AGE_75_84", {
            sf1: ["POP::#{stratum}::#{sex}::75_TO_79_YEARS", "POP::#{stratum}::#{sex}::80_TO_84_YEARS"],
            acs: ["POP::#{stratum}::#{sex}::75_TO_84_YEARS"]
          })
          const_set("#{stratum}_#{sex}_AGE_85_PLUS", ["POP::#{stratum}::#{sex}::85_YEARS_AND_OVER"])
        end

        const_set("#{stratum}_AGE_0_4",   compose(const_get("#{stratum}_MALE_AGE_0_4"), const_get("#{stratum}_FEMALE_AGE_0_4")))
        const_set("#{stratum}_AGE_5_9",   compose(const_get("#{stratum}_MALE_AGE_5_9"), const_get("#{stratum}_FEMALE_AGE_5_9")))
        const_set("#{stratum}_AGE_10_14", compose(const_get("#{stratum}_MALE_AGE_10_14"), const_get("#{stratum}_FEMALE_AGE_10_14")))
        const_set("#{stratum}_AGE_15_17", compose(const_get("#{stratum}_MALE_AGE_15_17"), const_get("#{stratum}_FEMALE_AGE_15_17")))
        const_set("#{stratum}_AGE_18_24", compose(const_get("#{stratum}_MALE_AGE_18_24"), const_get("#{stratum}_FEMALE_AGE_18_24")))
        const_set("#{stratum}_AGE_25_34", compose(const_get("#{stratum}_MALE_AGE_25_34"), const_get("#{stratum}_FEMALE_AGE_25_34")))
        const_set("#{stratum}_AGE_35_44", compose(const_get("#{stratum}_MALE_AGE_35_44"), const_get("#{stratum}_FEMALE_AGE_35_44")))
        const_set("#{stratum}_AGE_45_54", compose(const_get("#{stratum}_MALE_AGE_45_54"), const_get("#{stratum}_FEMALE_AGE_45_54")))
        const_set("#{stratum}_AGE_55_64", compose(const_get("#{stratum}_MALE_AGE_55_64"), const_get("#{stratum}_FEMALE_AGE_55_64")))
        const_set("#{stratum}_AGE_65_74", compose(const_get("#{stratum}_MALE_AGE_65_74"), const_get("#{stratum}_FEMALE_AGE_65_74")))
        const_set("#{stratum}_AGE_75_84", compose(const_get("#{stratum}_MALE_AGE_75_84"), const_get("#{stratum}_FEMALE_AGE_75_84")))
        const_set("#{stratum}_AGE_85_PLUS", compose(const_get("#{stratum}_MALE_AGE_85_PLUS"), const_get("#{stratum}_FEMALE_AGE_85_PLUS")))
      end

      #########
      # Race ##
      #########

      WHITE             = ['POP::WHITE_ALONE']
      BLACK             = ['POP::BLACK_OR_AFRICAN_AMERICAN_ALONE']
      NATIVE_AMERICAN   = ['POP::AMERICAN_INDIAN_AND_ALASKA_NATIVE_ALONE']
      ASIAN             = ['POP::ASIAN_ALONE']
      PACIFIC_ISLANDER  = ['POP::NATIVE_HAWAIIAN_AND_OTHER_PACIFIC_ISLANDER_ALONE']
      OTHER_RACE        = ['POP::SOME_OTHER_RACE_ALONE']
      TWO_OR_MORE_RACES = ['POP::TWO_OR_MORE_RACES']

      ##############
      ## Hispanic ##
      ##############

      HISPANIC     = ['POP::HISPANIC::TOTAL']
      NON_HISPANIC = ['POP::NOT_HISPANIC::TOTAL']
      NOT_HISPANIC = NON_HISPANIC

      ############
      ### Tests ##
      ###########

      # Used to protect against typos: these add up to the total population
      TEST_SUMS = {
        'AGE0' => [
          ALL_PEOPLE,
          (AGE_0_4 + AGE_5_9 + AGE_10_14 + AGE_15_17 + AGE_18_24 + AGE_25_34 + AGE_35_44 + AGE_45_54 + AGE_55_64 + AGE_65_74 + AGE_75_84 + AGE_85_PLUS),
        ],
        'SEX' => [
          ALL_PEOPLE,
          (MALE + FEMALE)
        ],
        'RACE' => [
          ALL_PEOPLE,
          (WHITE + BLACK + NATIVE_AMERICAN + ASIAN + PACIFIC_ISLANDER + OTHER_RACE + TWO_OR_MORE_RACES)
        ],
      }
    end
  end
end
