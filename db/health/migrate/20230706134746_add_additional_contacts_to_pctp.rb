###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddAdditionalContactsToPctp < ActiveRecord::Migration[6.1]
  def change
    [:guardian, :social_support].each do |label|
      [:name, :phone, :email].each do |kind|
        add_column :pctp_careplans, "#{label}_#{kind}", :string
      end
    end

    add_column :pctp_careplans, :name_sent_to, :string
  end
end
