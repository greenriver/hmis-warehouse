###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  # Simple content pages with paper_trail versioning (auditing only).
  # Can be used standalone (help, about) or linked to Compliance::Requirement.
  #
  # @see docs/features/compliance-requirements.md
  class ContentPage < GrdaWarehouseBase
    acts_as_paranoid
    has_paper_trail

    belongs_to :updated_by, class_name: 'User', optional: true
    has_many :compliance_requirements, class_name: 'GrdaWarehouse::Compliance::Requirement', dependent: :restrict_with_error

    has_rich_text :content

    before_validation :set_slug, on: :create

    validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/, message: 'only lowercase letters, numbers, and underscores' }
    validates :title, :content, presence: true

    scope :ordered, -> { order(:title, :id) }

    def to_param
      slug
    end

    private

    def set_slug
      return if slug.present?

      self.slug = title.to_s.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')
    end
  end
end
