###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class Agency < ApplicationRecord
  has_paper_trail
  has_many :users, dependent: :nullify
  has_many :agencies_consent_limits
  has_many :consent_limits, through: :agencies_consent_limits

  scope :text_search, -> (text) do
    return none unless text.present?

    where(arel_table[:name].lower.matches("%#{text.downcase}%"))
  end

end