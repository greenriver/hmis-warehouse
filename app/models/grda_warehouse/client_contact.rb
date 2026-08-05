###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class ClientContact < GrdaWarehouseBase
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :source, polymorphic: true

    include HasPiiAttributes
    pii_attr :first_name
    pii_attr :last_name
    pii_attr :full_name
    pii_attr :phone
    pii_attr :phone_alternate, as: :phone
    pii_attr :email
    pii_attr :address, as: :geo_street
    pii_attr :address2, as: :geo_street
    pii_attr :city, as: :geo_locality
    pii_attr :state, as: :geo_admin_1
    pii_attr :zip, as: :geo_postal_code
    pii_attr :note, as: :free_text

    scope :shelter_agency_contacts, -> do
      where(
        contact_type: [
          'Shelter Worker',
          'Housing Navigator',
          'Housing Case Manager',
          'Case Manager',
          'Rapid Re-Housing Case Manager',
          'Secondary Case Manager',
          'Assessor',
        ],
      )
    end

    scope :case_managers, -> do
      where(contact_type: ['Case Manager', 'Secondary Case Manager', 'Rapid Re-Housing Case Manager', 'Housing Navigator'])
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
        phone.presence,
        phone_alternate.presence,
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

    def full_address
      @full_address = [name]
      @full_address << "Phone: #{phone_numbers}" if phone_numbers.present?
      @full_address << "Email: #{email}" if email.present?
      @full_address << "Address: #{address_or_note}" if address_or_note.present?
      @full_address.compact.join("\n")
    end
  end
end
