###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::WorkerResponse < Types::BaseEnum
    description 'R19.A'
    graphql_name 'WorkerResponse'
    value NO, '(0) No', value: 0
    value YES, '(1) Yes', value: 1
    value WORKER_DOES_NOT_KNOW, '(2) Worker does not know', value: 2
  end
end
