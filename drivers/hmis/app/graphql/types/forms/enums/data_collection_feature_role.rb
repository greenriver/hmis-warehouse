###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::DataCollectionFeatureRole < Types::BaseEnum
    graphql_name 'DataCollectionFeatureRole'

    with_enum_map Hmis::Form::Definition.data_collection_feature_role_enum_map, prefix_description_with_key: false
  end
end
