###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Filterable
  extend ActiveSupport::Concern

  module ClassMethods
    def filter(filter_by)
      results = where(nil)
      filter_by.each do |key, value|
        value.reject!(&:blank?) if value.is_a? Array
        results = results.where(key => value) if value.present?
      end
      results
    end
  end
end
