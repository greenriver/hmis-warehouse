###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::DataCollectedAbout < Types::BaseEnum
    graphql_name 'DataCollectedAbout'

    Hmis::Form::InstanceEnrollmentMatch::MATCHES.each do |val|
      description = val.titleize.
        gsub(/\bHoh\b/, 'HoH').
        gsub(/\bSsvf\b/, 'SSVF').
        gsub(/\bAnd\b/, 'and')
      value val, description, value: val
    end
  end
end
