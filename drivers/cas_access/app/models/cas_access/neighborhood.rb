###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  class Neighborhood < CasBase
    self.table_name = :neigborhoods
    def self.neighborhood_ids_from_names(names)
      return [] unless db_exists?
      return [] unless names&.map(&:presence)&.compact&.any?

      where(name: names).pluck(:id)
    end
  end
end
