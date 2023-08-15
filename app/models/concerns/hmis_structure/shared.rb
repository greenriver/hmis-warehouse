###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisStructure::Shared
  extend ActiveSupport::Concern

  included do
    ['2022', '2024'].each do |version|
      hmis_configuration(version: version).keys.each do |col|
        alias_attribute col.to_s.underscore.to_sym, col
      end
    end
  end
end
