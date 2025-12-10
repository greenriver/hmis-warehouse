###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Compliance
  # Records user acceptance of a compliance requirement.
  # Tracks which requirement revision was agreed to for audit purposes.
  #
  # @see docs/features/compliance-requirements.md
  class Agreement < GrdaWarehouseBase
    self.table_name = 'compliance_agreements'

    acts_as_paranoid

    belongs_to :user
    belongs_to :requirement, class_name: 'GrdaWarehouse::Compliance::Requirement', foreign_key: :compliance_requirement_id

    validates :agreed_at, :revision, presence: true

    scope :for_requirement, ->(requirement) { where(compliance_requirement_id: requirement.id) }
    scope :for_user, ->(user) { where(user: user) }
    scope :not_expired, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
    scope :expired, -> { where('expires_at <= ?', Time.current) }

    def expired?
      expires_at.present? && expires_at <= Time.current
    end
  end
end
