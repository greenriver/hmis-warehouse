###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Cas
  class Neighborhood < CasBase
    def self.neighborhood_ids_from_names(names)
      return [] unless db_exists?
      return [] unless names&.map(&:presence)&.compact&.any?

      where(name: names).pluck(:id)
    end
  end
end
