###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Cas
  class User < CasBase
    has_one :contact
    belongs_to :agency, optional: true

    scope :in_directory, -> do
      preload(:contact, :agency).
      where(active: true, exclude_from_directory: false)
    end

    scope :text_search, ->(text) do
      where("first_name LIKE :text OR last_name LIKE :text OR email LIKE :text", text: "%#{text}%")
    end

    def name
      "#{first_name} #{last_name}"
    end

    def phone_for_directory
      if contact.present?
        contact.phone unless exclude_phone_from_directory
      end
    end

    def agency_name
      if agency.present?
        agency&.name
      end
    end
  end
end
