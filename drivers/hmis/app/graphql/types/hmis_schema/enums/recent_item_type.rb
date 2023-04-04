###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::RecentItemType < Types::BaseEnum
    description 'Types allowed for recent items'
    graphql_name 'RecentItemType'

    [
      Hmis::Hud::Project,
      Hmis::Hud::Client,
    ].each do |item_class|
      value item_class.name.split('::').last, value: item_class
    end
  end
end
