# frozen_string_literal: true

class HmisTableConfiguration < ApplicationRecord
  belongs_to :owner, polymorphic: true, optional: true

  validates :table_key, presence: true, uniqueness: { scope: [:owner_type, :owner_id], message: 'must be unique per owner' }
  validates :data_source_id, presence: true
  validates :columns, presence: true
  validates :filters, presence: true

  # Add any additional methods or scopes here if needed
end
