###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::HMIS
  class Base < GrdaWarehouse::Hud::Base
    self.abstract_class = true
    PREFIX = 'hmis_'

    # use for association table names with models in GrdaWarehouse::HMIS
    def self.dub(name)
      self.table_name = PREFIX + name
    end

    # unreliable connection to originating object
    def source_object
      (
        @source_object ||= if respond_to?(:source_class)
          source = source_class.constantize.find(source_id) rescue nil   # if we can't establish the source connection, just return nil
          [source]
        else
          []
        end
      )[0]
    end
  end
end
