###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Loaders
  class BaseLoader
    def self.perform(...)
      new.perform(...)
    end

    protected

    def row_value(row, field:)
      row[field]&.strip&.presence
    end

    def system_user_id
      @system_user_id || Hmis::Hud::User.system_user(data_source_id: data_source.id).user_id
    end

    def data_source
      HmisExternalApis::AcHmis.data_source
    end

    def default_attrs
      {
        data_source_id: data_source.id,
        UserID: system_user_id,
      }
    end

    def today
      @today ||= Date.current
    end
  end
end
