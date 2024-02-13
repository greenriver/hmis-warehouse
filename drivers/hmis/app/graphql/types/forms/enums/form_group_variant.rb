###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Forms::Enums::FormGroupVariant < Types::BaseEnum
    graphql_name 'Variant'
    value 'SIGNATURE', 'Render a signature envelope'
    value 'HIGHLIGHT', 'Render form group with a highlighted bar'
  end
end
