###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class FixupContacts < ActiveRecord::Migration[7.1]
  def up
    users = nil
    ApplicationRecord.connected_to(role: :reading) do
      users = User.pluck(:email, :id).to_h
    end

    GrdaWarehouseBase.connected_to(role: :writing) do
      now = Time.current
      GrdaWarehouse::Contact::Base.find_each do |contact|
        # We only ever send email to people with valid accounts, so we'll delete any that would never work
        id = users[contact.email]
        puts "Contact #{contact.id} has email #{contact.email} and user #{id}"
        contact.update(deleted_at: now) unless id

        puts "Updating contact #{contact.id} to user #{id}"
        contact.update(user_id: id)
      end
    end
  end
end
