###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

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
