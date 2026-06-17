###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ConsentLimit < ApplicationRecord
  has_paper_trail
  acts_as_paranoid

  has_many :agencies_consent_limits
  has_many :agencies, through: :agencies_consent_limits

  validates_presence_of :name, :color
  validates :name, format: { with: /\A[A-Z][A-Z]-\d\d\d\z/, message: "Must match the format ZZ-000" }

  def self.available_cocs
    all.map do |c|
      [
        "#{c.description} (#{c.name})",
        c.id,
      ]
    end
  end

  def self.available_coc_codes
    all.map do |c|
      [
        "#{c.description} (#{c.name})",
        c.name, # name is the CoC Code
      ]
    end
  end

  def description_and_coc_code
     "#{description} (#{name})"
  end
end
