###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::Transformers::BaseTransformer
    attr_reader :input

    def initialize(input)
      @input = input
    end

    def method_missing(method, *args, &block)
      input.send(method, *args, &block) if input.respond_to?(method)
    end

    def respond_to_missing?(name, include_private = false)
      input.respond_to?(name, include_private)
    end

    def to_params
      to_h
    end
  end
end
