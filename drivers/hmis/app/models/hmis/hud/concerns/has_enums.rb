###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
module Hmis::Hud::Concerns::HasEnums
  extend ActiveSupport::Concern

  class_methods do
    def use_enum(name, hash, **kwargs)
      if block_given?
        values = yield hash
      else
        values = hash.map do |key, desc|
          {
            key: desc,
            value: key,
            desc: desc,
          }
        end
      end

      define_singleton_method(name) do
        Hmis::FieldMap.new(values, **kwargs)
      end
    end

    def use_common_enum(name, type = :no_yes)
      raise ArgumentError, "Common enum \"#{type}\" does not exist" unless Hmis::FieldMap.respond_to?(type)

      define_singleton_method(name) { Hmis::FieldMap.send(type) }
    end

    def use_enum_with_same_key(name, hash, **kwargs)
      values = hash.map do |key, desc|
        {
          key: key.to_s,
          value: key.to_s,
          desc: desc,
        }
      end

      define_singleton_method(name) do
        Hmis::FieldMap.new(values, **kwargs)
      end
    end
  end
end
