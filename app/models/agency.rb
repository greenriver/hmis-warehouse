###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class Agency < ApplicationRecord
  has_many :users, dependent: :nullify

  scope :text_search, -> (text) do
    return none unless text.present?

    where(arel_table[:name].lower.matches("%#{text.downcase}%"))
  end

end