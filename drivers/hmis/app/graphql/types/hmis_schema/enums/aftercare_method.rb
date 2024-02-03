###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::AftercareMethod < Types::BaseEnum
    graphql_name 'AftercareMethod'
    # Used for R20 Aftercare Plans
    # Page 82 https://files.hudexchange.info/resources/documents/HMIS-Data-Dictionary-2024.pdf

    value 'VIA_EMAIL_SOCIAL', 'Via email/social media', value: 1
    value 'VIA_TEL', 'Via telephone', value: 2
    value 'IN_PERSON_1_ON_1', 'In person: one-on-one', value: 3
    value 'IN_PERSON_GROUP', 'In person: group', value: 4
  end
end
