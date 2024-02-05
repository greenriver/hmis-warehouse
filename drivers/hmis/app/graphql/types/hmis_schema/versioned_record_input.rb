###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::VersionedRecordInput < Types::BaseInputObject
    argument :id, ID, required: true
    argument :lock_version, Integer, required: false
  end
end
