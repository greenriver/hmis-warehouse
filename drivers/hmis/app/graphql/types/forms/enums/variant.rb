###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::Variant < Types::BaseEnum
    graphql_name 'Variant'
    value 'SIGNATURE', 'Render a signature envelope'
  end
end
