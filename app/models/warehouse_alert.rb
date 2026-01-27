###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class WarehouseAlert < ApplicationRecord
  belongs_to :user, optional: true
  acts_as_paranoid

  scope :ordered, -> do
    order(created_at: :desc)
  end
end
