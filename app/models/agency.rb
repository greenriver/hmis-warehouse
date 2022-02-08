###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
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

  scope :publically_available, -> do
    where(expose_publically: true)
  end

  def description_and_coc_code
    text = name
    if consent_limits.exists?
      text += " in " + consent_limits.map(&:description_and_coc_code).to_sentence
    end
    text
  end
end
