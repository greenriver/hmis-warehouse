###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class ClientContact < GrdaWarehouseBase
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :source, polymorphic: true

    scope :shelter_agency_contacts, -> do
      where(contact_type: 'Shelter Worker')
    end

    scope :newest_first, -> do
      order(last_modified_at: :desc)
    end

    def name
      return full_name if full_name.present?

      "#{first_name} #{last_name}"
    end

    def phone_numbers
      [
        phone,
        phone_alternate,
      ].compact.join(', ')
    end

    def address_or_note
      city_state = [city, state].join(', ')
      specified_address = [
        address,
        address2,
        [city_state, zip].join(' '),
      ].compact.join("\n")

      [
        specified_address,
        note,
      ].join("\n")
    end
  end
end
