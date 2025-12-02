###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Compliance
  # Defines a policy that users must agree to before accessing the site.
  # Links to a ContentPage that contains the actual terms/policy text.
  # Agreements expire when revision increments or expires_after_days is reached.
  #
  # @see docs/features/compliance-requirements.md
  class Requirement < GrdaWarehouseBase
    self.table_name = 'compliance_requirements'

    acts_as_paranoid
    has_paper_trail

    belongs_to :content_page, class_name: 'GrdaWarehouse::ContentPage'
    has_many :agreements, class_name: 'GrdaWarehouse::Compliance::Agreement', foreign_key: :compliance_requirement_id, dependent: :restrict_with_error

    validates :name, presence: true
    validates :revision, numericality: { only_integer: true, greater_than: 0 }
    validates :expires_after_days, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

    scope :ordered, -> { order(:position, :id) }
    scope :active, -> { where(active: true) }

    def self.pending_for_user(user)
      valid_requirement_ids = GrdaWarehouse::Compliance::Agreement
        .for_user(user)
        .not_expired
        .joins(:requirement)
        .where('compliance_agreements.revision >= compliance_requirements.revision')
        .select(:compliance_requirement_id)

      active.where.not(id: valid_requirement_ids)
    end
  end
end
