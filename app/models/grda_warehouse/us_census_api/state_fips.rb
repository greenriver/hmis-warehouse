###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#
# This information is available from the Shape::State model too
module GrdaWarehouse
  module UsCensusApi
    class StateFIPS < Struct.new(:state_code)
      def code
        result = {
          'AL' => '01', # Alabama
          'AK' => '02', # Alaska
          'AZ' => '04', # Arizona
          'AR' => '05', # Arkansas
          'CA' => '06', # California
          'CO' => '08', # Colorado
          'CT' => '09', # Connecticut
          'DE' => '10', # Delaware
          'FL' => '12', # Florida
          'GA' => '13', # Georgia
          'HI' => '15', # Hawaii
          'ID' => '16', # Idaho
          'IL' => '17', # Illinois
          'IN' => '18', # Indiana
          'IA' => '19', # Iowa
          'KS' => '20', # Kansas
          'KY' => '21', # Kentucky
          'LA' => '22', # Louisiana
          'ME' => '23', # Maine
          'MD' => '24', # Maryland
          'MA' => '25', # Massachusetts
          'MI' => '26', # Michigan
          'MN' => '27', # Minnesota
          'MS' => '28', # Mississippi
          'MO' => '29', # Missouri
          'MT' => '30', # Montana
          'NE' => '31', # Nebraska
          'NV' => '32', # Nevada
          'NH' => '33', # New Hampshire
          'NJ' => '34', # New Jersey
          'NM' => '35', # New Mexico
          'NY' => '36', # New York
          'NC' => '37', # North Carolina
          'ND' => '38', # North Dakota
          'OH' => '39', # Ohio
          'OK' => '40', # Oklahoma
          'OR' => '41', # Oregon
          'PA' => '42', # Pennsylvania
          'RI' => '44', # Rhode Island
          'SC' => '45', # South Carolina
          'SD' => '46', # South Dakota
          'TN' => '47', # Tennessee
          'TX' => '48', # Texas
          'UT' => '49', # Utah
          'VT' => '50', # Vermont
          'VA' => '51', # Virginia
          'WA' => '53', # Washington
          'WV' => '54', # West Virginia
          'WI' => '55', # Wisconsin
          'WY' => '56', # Wyoming
          'AS' => '60', # American Samoa
          'GU' => '66', # Guam
          'MP' => '69', # Northern Mariana Islands
          'PR' => '72', # Puerto Rico
          'VI' => '78', # Virgin Islands
        }[state_code]

        if result
          result
        else
          raise "#{state_code} is not a valid code"
        end
      end
    end
  end

end
