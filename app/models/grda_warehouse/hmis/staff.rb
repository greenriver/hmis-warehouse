###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::HMIS
  class Staff <  Base
    dub 'staff'

    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
    has_many :staff_x_clients, inverse_of: :staff, dependent: :delete_all
    has_many :clients, through: :staff_x_clients

    def mi
      if m = middle_initial.presence
        m.strip.titlecase.sub( /(\w)$/, '\1.' )
      end
    end

    def name
      [ first_name.presence, mi, last_name.presence ].compact.join(' ')
    end

  end
end
