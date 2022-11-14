###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::ProjectCompletionStatus < Types::BaseEnum
    description 'R17.1'
    graphql_name 'ProjectCompletionStatus'
    value 'COMPLETED_PROJECT', '(1) Completed project', value: 1
    value 'YOUTH_VOLUNTARILY_LEFT_EARLY', '(2) Youth voluntarily left early', value: 2
    value 'YOUTH_WAS_EXPELLED_OR_OTHERWISE_INVOLUNTARILY_DISCHARGED_FROM_PROJECT', '(3) Youth was expelled or otherwise involuntarily discharged from project', value: 3
  end
end
