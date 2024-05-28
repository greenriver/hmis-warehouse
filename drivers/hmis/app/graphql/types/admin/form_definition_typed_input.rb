#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Types
  class Admin::FormDefinitionTypedInput < Types::BaseInputObject
    argument :item, ['Types::Admin::FormItemInput'], required: true
  end
end
