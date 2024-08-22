###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Forms::FormItemRule < Types::BaseObject
    skip_activity_log

    field :parts, [Forms::FormItemRule], 'Parts that make up this rule', null: true

    field :variable, String, null: true
    field :value, String, null: true
    field :operator, String, null: true
    field :_comment, String, null: true
  end
end
