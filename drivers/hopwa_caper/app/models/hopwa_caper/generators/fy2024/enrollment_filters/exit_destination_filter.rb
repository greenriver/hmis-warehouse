###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  ExitDestinationFilter = Struct.new(:label, :types, keyword_init: true) do
    def apply(scope)
      return nil unless types

      scope.where(exit_destination: codes)
    end

    protected def codes
      lookups = HudUtility2024.destinations.invert
      types.map do |type|
        lookups.fetch(type)
      end
    end

    def self.other_hopwa_program
      new(
        label: 'How many households exited to other HOPWA housing programs?',
        types: [
          'Moved from one HOPWA funded project to HOPWA TH',
          'Moved from one HOPWA funded project to HOPWA PH',
        ],
      )
    end

    def self.other_subsidy_program
      new(
        label: 'How many households exited to other housing subsidy programs?',
        types: [
          'Owned by client, with ongoing housing subsidy',
          'Rental by client, with ongoing housing subsidy',
        ],
      )
    end

    def self.private_housing
      new(
        label: 'How many households exited to private housing?',
        types: [
          'Rental by client, no ongoing housing subsidy',
          'Owned by client, no ongoing housing subsidy',
        ],
      )
    end

    def self.deceased
      new(label: 'Deceased', types: ['Deceased'])
    end

    def self.php_destinations
      [
        other_hopwa_program,
        other_subsidy_program,
        private_housing,
      ]
    end

    def self.all_destinations
      type_unknown = nil

      [
        other_hopwa_program,
        other_subsidy_program,
        new(
          label: 'How many households exited to an emergency shelter?',
          types: [
            'Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or Host Home shelter'
          ],
        ),
        private_housing,
        new(
          label: 'How many households exited to transitional housing (time limited - up to 24 months)?',
          types: ['Transitional housing for homeless persons (including homeless youth)'],
        ),
        new(
          label: 'an institutional arrangement expected to last less than six months',
          types: type_unknown,
        ),
        new(
          label: 'How many households exited to institutional arrangement expected to last more than six months?',
          types: type_unknown,
        ),
        new(
          label: 'a jail/prison term expected to last less than six months',
          types: type_unknown,
        ),
        new(
          label: 'a jail/prison term expected to last more than six months',
          types: type_unknown,
        ),
        new(
          label: "a situation that isn't transitional, but is not expected to last more than 90 days and their housing situation after those 90 days is uncertain",
          types: type_unknown,
        ),
        new(
          label: 'How many households exited to a place not meant for human habitation?',
          types: [
            'Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)',
          ],
        ),
        new(
          label: 'How many households were disconnected from care?',
          types: type_unknown,
        ),
      ]
    end

  end
end
