###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  ExitDestinationFilter = Struct.new(:label, :types, keyword_init: true) do
    def apply(scope)
      scope.where(exit_destination: codes)
    end

    protected def codes
      HudUtility2024.destinations.invert
      types.map do |type|
        HudUtility2024.destinations.invert.fetch(type)
      end
    end

    def self.all_destinations
      HudUtility2024.destinations.map do |_code, label|
        new(label: label, types: [label])
      end
    end

    def self.php_destinations
      [
        new(
          label: 'How many households exited to other HOPWA housing programs?',
          types: [
            'Moved from one HOPWA funded project to HOPWA TH',
            'Moved from one HOPWA funded project to HOPWA PH',
          ],
        ),
        new(
          label: 'How many households exited to other housing subsidy programs?',
          types: [
            'Owned by client, with ongoing housing subsidy',
            'Rental by client, with ongoing housing subsidy',
          ],
        ),
        new(
          label: 'How many households exited to private housing?',
          types: [
            'Rental by client, no ongoing housing subsidy',
            'Owned by client, no ongoing housing subsidy',
          ],
        ),
      ]
    end

    # FIXME: it's unclear how we can implement the spec below. Returning exit destinations for now
    # def self.all
    #  [
    #    new(
    #      label: 'other HOPWA housing programs',
    #      types: [
    #        "Moved from one HOPWA funded project to HOPWA TH",
    #        "Moved from one HOPWA funded project to HOPWA PH",
    #      ]
    #    ),
    #    new(
    #      label: 'other housing subsidy programs',
    #      types: [],
    #    ),
    #    new(
    #      label: 'an emergency shelter',
    #      types: "Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or Host Home shelter",
    #    ),
    #    new(
    #      label: 'private housing',
    #      types: [
    #      ],
    #    ),
    #    new(
    #      label: 'transitional housing (time limited - up to 24 months)',
    #      types: [
    #        "Transitional housing for homeless persons (including homeless youth)"
    #      ]
    #    ),
    #    new(
    #      label: 'an institutional arrangement expected to last less than six months',
    #      types: [
    #        "Long-term care facility or nursing home",
    #        "Psychiatric hospital or other psychiatric facility",
    #      ],
    #    ),
    #    new(
    #      label: 'How many households exited to institutional arrangement expected to last more than six months?',
    #      types: [
    #        "Long-term care facility or nursing home",
    #        "Psychiatric hospital or other psychiatric facility",
    #      ],
    #    ),
    #    new(
    #      label: 'a jail/prison term expected to last less than six months',
    #      types: ,
    #    ),
    #    new(
    #      label: 'a jail/prison term expected to last more than six months',
    #      types: "Jail, prison or juvenile detention facility",
    #    ),
    #    new(
    #      label: "a situation that isn't transitional, but is not expected to last more than 90 days and their housing situation after those 90 days is uncertain",
    #      types: [],
    #    ),
    #    new(
    #      label: 'a place not meant for human habitation',
    #      types: "Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)",
    #    ),
    #    new(
    #      label: 'How many of the HOPWA eligible individuals died?',
    #      types: 'Deceased',
    #    ),
    #  ]
    # end
  end
end
