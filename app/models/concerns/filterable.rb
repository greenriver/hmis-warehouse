module Filterable
  extend ActiveSupport::Concern

  module ClassMethods
    def filter(filter_by)
      results = self.where(nil)
      filter_by.each do |key, value|
        if value.is_a? Array
          value.reject!(&:blank?)
        end
        results = results.where(key => value) if value.present?
      end
      results
    end
  end
end