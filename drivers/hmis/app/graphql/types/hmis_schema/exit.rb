###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Exit < Types::BaseObject
    def self.configuration
      Hmis::Hud::Exit.hmis_configuration(version: '2022')
    end

    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :user, HmisSchema::User, null: true
    hud_field :exit_date, null: false
    hud_field :destination, Types::HmisSchema::Enums::Hud::Destination, null: false
    hud_field :other_destination
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted

    # TODO: FPDE

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def client
      load_ar_association(object, :client)
    end

    def user
      load_ar_association(object, :user)
    end
  end
end
