###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::Component < Types::BaseEnum
    graphql_name 'Component'

    value 'INPUT_GROUP', 'Component to render a group that contains children of the same type (eg all booleans). Optionally has a choice item, which must be the first item.'
    value 'CHECKBOX', 'Component to render a boolean input item as a checkbox'
    value 'WARNING_ALERT', 'Display text as a warning alert'
    # value 'RADIO_BUTTONS', 'Component to render a choice input item as radio buttons'
  end
end
