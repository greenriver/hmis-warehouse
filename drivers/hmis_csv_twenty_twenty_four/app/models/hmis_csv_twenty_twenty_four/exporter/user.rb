###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Exporter
  class User
    include ::HmisCsvTwentyTwentyFour::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

    # Append a system user record to cover records where the user wasn't available
    def close
      user = ::User.system_user
      row =  GrdaWarehouse::Hud::User.new(
        UserID: 'op-system',
        UserFirstName: user.first_name,
        UserLastName: user.last_name,
        UserEmail: user.email,
        DateCreated: Time.current,
        DateUpdated: Time.current,
        ExportID: @options[:export].export_id,
      )
      yield row
    end

    def self.adjust_keys(row, _export)
      row.UserID = row.id

      row
    end

    def self.export_scope(export:, hmis_class:, **_)
      hmis_class.where(id: export.user_ids.to_a)
    end

    def self.transforms
      [
        HmisCsvTwentyTwentyFour::Exporter::User,
        HmisCsvTwentyTwentyFour::Exporter::FakeData,
      ]
    end
  end
end
