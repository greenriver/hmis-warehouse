###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::Component < Types::BaseEnum
    graphql_name 'Component'

    value 'INPUT_GROUP', 'Render a group that contains children of the same type (e.g. all booleans)'
    # value 'REPEATED_INPUT_GROUP', 'Group that contains children of the same field type (e.g. all names) that should be revealed 1-at-a-time'
    value 'DISABILITY_TABLE', 'Specialized component for rendering disabilities in a table'
    value 'HORIZONTAL_GROUP', 'Render a group of inputs horizontally'
    value 'INFO_GROUP', 'Render contents in an info box'

    value 'CHECKBOX', 'Render a boolean input item as a checkbox'
    value 'RADIO_BUTTONS', 'Render a choice input item as radio buttons'
    value 'RADIO_BUTTONS_VERTICAL', 'Render a choice input item as vertical radio buttons'
    value 'ALERT_INFO', 'Display text as an info alert'
    value 'ALERT_WARNING', 'Display text as a warning alert'
    value 'ALERT_ERROR', 'Display text as an error alert'
    value 'ALERT_SUCCESS', 'Display text as a success alert'
    value 'SSN', 'SSN input component'
    value 'MCI', 'MCI linking component'
    value 'NAME', 'Client Name input'
    value 'ADDRESS', 'Client Address input'
    value 'PHONE', 'Phone number input for ContactPoint'
    value 'EMAIL', 'Email address input for ContactPoint'
  end
end
