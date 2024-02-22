###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::DisplayHook < Types::BaseEnum
    description 'Application for displaying Custom Data Element values'

    value 'TABLE_SUMMARY', 'Display value as a column when viewing a table of records (e.g. Current Living Situations)'

    # Additional hooks that may be added later:
    # value 'CLIENT_DEMOGRAPHICS', 'Display value in the Client Demographics section of the Client Dashboard'
    # value 'CLIENT_HIGHLIGHT', 'Display prominently on the client dashboard'
    # value 'ENROLLMENT_SUMMARY', 'Display in the enrollment details card on the Enrollment Dashboard'
  end
end
