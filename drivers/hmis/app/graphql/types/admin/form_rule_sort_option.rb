###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Admin::FormRuleSortOption < Types::BaseEnum
    graphql_name 'FormRuleSortOption'

    Hmis::Form::Instance::SORT_OPTIONS.each do |opt|
      value opt.to_s.upcase, value: opt, description: opt.to_s.titleize
    end
  end
end
