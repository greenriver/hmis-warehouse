###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hmis
  class Staff < Base
    dub 'staff'

    include HasPiiAttributes
    pii_attr :first_name
    pii_attr :middle_initial, as: :middle_name
    pii_attr :last_name
    pii_attr :ssn
    pii_attr :work_phone, as: :phone
    pii_attr :cell_phone, as: :phone
    pii_attr :email

    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
    has_many :staff_x_clients, inverse_of: :staff, dependent: :delete_all
    has_many :clients, through: :staff_x_clients

    def mi
      middle_initial.strip.titlecase.sub(/(\w)$/, '\1.') if middle_initial.present?
    end

    def name
      [first_name.presence, mi, last_name.presence].compact.join(' ')
    end
  end
end
