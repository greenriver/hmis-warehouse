###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Code initially written for and funded by Delaware Health and Social Services.
# Used and modified with permission.
#
# We get the entire corpus of variables from the census.
# Then, we use this class to specify what subset of these we want the values
# for and to compute/save the internal name.

# This is only set up to work for populations, but can be extended for other
# types of variables.

module GrdaWarehouse
  module UsCensusApi
    class RelevantVariables
      class VarSet
        attr_accessor :general_type, :subcategory, :census_group, :whitelist, :blacklist

        def initialize(args)
          self.blacklist = []
          self.whitelist = []
          self.subcategory = '*'
          self.general_type = 'POP'
          args.each do |key, val|
            send("#{key}=", val)
          end
        end
      end

      VARSETS = [
        VarSet.new(general_type: 'POP', census_group: 'P1'     , subcategory: '*'                      ), # Total population
        VarSet.new(general_type: 'POP', census_group: 'P3'     , subcategory: '*'                      ), # Racial population
        VarSet.new(general_type: 'POP', census_group: 'P4'     , subcategory: '*'                      ), # hispanic/not-hispanic population

        # sex by age for 2010 census
        VarSet.new(general_type: 'POP', census_group: 'P12A'   , subcategory: 'WHITE'                  ),
        VarSet.new(general_type: 'POP', census_group: 'P12B'   , subcategory: 'BLACK'                  ),
        VarSet.new(general_type: 'POP', census_group: 'P12C'   , subcategory: 'NATIVE_AMERICAN'        ),
        VarSet.new(general_type: 'POP', census_group: 'P12D'   , subcategory: 'ASIAN'                  ),
        VarSet.new(general_type: 'POP', census_group: 'P12E'   , subcategory: 'PACIFIC_ISLANDER'       ),
        VarSet.new(general_type: 'POP', census_group: 'P12F'   , subcategory: 'OTHER_RACE'             ),
        VarSet.new(general_type: 'POP', census_group: 'P12G'   , subcategory: 'MULTI_RACIAL'           ),
        VarSet.new(general_type: 'POP', census_group: 'P12H'   , subcategory: 'HISPANIC'               ),
        VarSet.new(general_type: 'POP', census_group: 'P12I'   , subcategory: 'NOT_HISPANIC'           ), # white alone, not hispanic

        # Sex by age acs (i.e. within the subcategory, broken out into sex and age-ranges at the same time)
        VarSet.new(general_type: 'POP', census_group: 'B01001A', subcategory: 'WHITE'                  ),
        VarSet.new(general_type: 'POP', census_group: 'B01001B', subcategory: 'BLACK'                  ),
        VarSet.new(general_type: 'POP', census_group: 'B01001C', subcategory: 'NATIVE_AMERICAN'        ),
        VarSet.new(general_type: 'POP', census_group: 'B01001D', subcategory: 'ASIAN'                  ),
        VarSet.new(general_type: 'POP', census_group: 'B01001E', subcategory: 'PACIFIC_ISLANDER'       ),
        VarSet.new(general_type: 'POP', census_group: 'B01001F', subcategory: 'OTHER_RACE'             ),
        VarSet.new(general_type: 'POP', census_group: 'B01001G', subcategory: 'MULTI_RACIAL'           ),
        VarSet.new(general_type: 'POP', census_group: 'B01001H', subcategory: 'NOT_HISPANIC'           ),
        VarSet.new(general_type: 'POP', census_group: 'B01001I', subcategory: 'HISPANIC'               ), # ACS and sf1 have switched semantics for I and H. Very confusing.


        VarSet.new(general_type: 'POP', census_group: 'P12'    , subcategory: '*'                      ), # Sex by age for whole population decennial
        VarSet.new(general_type: 'POP', census_group: 'B01001' , subcategory: '*'                      ), # Sex by age
        VarSet.new(general_type: 'POP', census_group: 'B02001' , subcategory: '*'                      ), # Racial populations
        VarSet.new(general_type: 'POP', census_group: 'B01003' , subcategory: '*'                      ), # total population
      ]

      def link_up!
        #return if _no_work?

        Rails.logger.info "Naming the variables we care about"

        CensusVariable.transaction do
          CensusVariable.where.not(dataset: 'imputed').update_all(internal_name: nil)

          VARSETS.each do |varset|
            CensusVariable.where(census_group: varset.census_group).find_each do |cv|
              next if cv.name.in?(varset.blacklist)

              if varset.whitelist.present?
                next unless cv.name.in?(varset.whitelist)
              end

              internal_name = make_internal_name(cv, varset)

              cv.update_attribute(:internal_name, internal_name)
            end
          end
        end
      end

      private

      # Wrangle variations across years and datasets into a standard way to
      # refer to the variables we care about
      def make_internal_name(cv, varset)
        starting = cv.label.
          sub(/Total:?!!/, '').
          sub(/Estimate!!/, '').
          sub(/!!/, '::').
          upcase

        middle = \
          case varset.subcategory
        when 'POVERTY_STATUS_BY_AGE'
          starting.
            sub(/income.in.the.past.12.months.at.or.above.poverty.level/i, 'AT_OR_ABOVE_POVERTY_LEVEL').
            sub(/income.in.the.past.12.months.below.poverty.level/i, 'BELOW_POVERTY_LEVEL')
        when 'MEDIAN_HOUSEHOLD_INCOME'
          starting.sub(/MEDIAN.HOUSEHOLD.+INFLATION.ADJUSTED.DOLLARS./i, 'AMOUNT')
        when 'YEAR_BUILT'
          starting.
            sub(/built./i, '')
        else
          starting.sub(/MEDIAN_AGE_BOTH_SEXES/i, 'MEDIAN_AGE_TOTAL')
        end

        name = middle.
          gsub(/[^A-Z0-9:*]/, '_').
          squeeze('_').
          sub(/^_/, '').
          gsub(/:_/, ':')

        full_name = ("#{varset.general_type}::#{varset.subcategory}::"+name).
          split(/:/).
          reject { |token| token.blank? || token == '*' }.
          join('::')

        if !full_name.match?(CensusVariable::VALID_NAME)
          raise "#{full_name} is not a valid name. Fix the crazy logic above and update 'spec/models/us_census_api/census_variable_spec.rb'"
        end

        full_name
      end
  end
end
end
