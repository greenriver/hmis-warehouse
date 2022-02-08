###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Token < ApplicationRecord

  # initially make tokens valid for one month
  scope :valid, -> do
    where(created_at: (validity_length.ago..Time.now)).
    where(arel_table[:expires_at].eq(nil).or(arel_table[:expires_at].lt(Time.now)))
  end

  def self.validity_length
    1.months
  end

  def self.tokenize path
    create(
      token: SecureRandom.uuid,
      path: path,
    )
  end
end
