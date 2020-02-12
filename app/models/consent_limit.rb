###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class ConsentLimit < ActiveRecord::Base
  has_paper_trail
  acts_as_paranoid

  has_many :agencies_consent_limits
  has_many :agencies, through: :agencies_consent_limits

  validates_presence_of :name, :color
  validates :name, format: { with: /[A-Z][A-Z]-\d\d\d/, message: "Must match the format ZZ-000" }

  def self.available_cocs
    all.map do |c|
      [
        "#{c.description} (#{c.name})",
        c.id,
      ]
    end
  end
end
