###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class AcHmis::ClearMci < BaseMutation
    description 'Submit a form to create/update HUD record(s)'

    argument :input, Types::AcHmis::MciClearanceInput, required: true

    field :matches, [Types::AcHmis::MciClearanceMatch], null: true

    def resolve(input:)
      # TODO: error if MCI connection isn't set up
      mci = HmisExternalApis::Mci.new
      # TODO: try catch
      matches = mci.clearance(input.to_client)
      _result = matches.map { |m| Types::AcHmis::MciClearanceMatch.from_mci_clearance_result(m) }

      {
        matches: [
          {
            id: 1,
            score: 80,
            clent: {
              id: 2,
              mci_id: '1234234',
              first_name: 'foo',
              last_name: 'bar',
              dob: 30.years.ago,
              age: 30,
            },
          },
        ],
        errors: [],
      }
    end
  end
end
