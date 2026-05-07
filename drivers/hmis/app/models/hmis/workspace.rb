###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  # Configuration for HMIS context switchers.
  #
  # A workspace ties an existing Hmis::ProjectGroup to a specific UI/application
  # usage, such as the CE referrals page. It does not define membership itself
  # and it is not an access-control boundary; project membership and permissions
  # remain governed by ProjectGroup and the normal HMIS access model.
  #
  # Future usages may include similar context switchers elsewhere in HMIS,
  # such as the user dashboard.
  class Workspace < Hmis::HmisBase
    self.table_name = 'hmis_workspaces'

    CE_REFERRALS = 'ce_referrals'
    APPLIES_TO = [
      CE_REFERRALS,
    ].freeze

    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
    belongs_to :project_group, class_name: 'Hmis::ProjectGroup', foreign_key: :hmis_project_group_id

    validates :applies_to, inclusion: { in: APPLIES_TO }
    validates :slug, uniqueness: { scope: [:applies_to, :data_source_id] }
    validates :name, uniqueness: { scope: [:applies_to, :data_source_id] }
    validates :sort_order, uniqueness: { scope: [:applies_to, :data_source_id] }
    validate :data_source_must_be_hmis
    validate :data_source_must_match_project_group

    scope :active, -> { where(active: true) }
    scope :for_usage, ->(applies_to) { where(applies_to: applies_to) }
    scope :ordered, -> { order(:sort_order, :id) }

    private

    def data_source_must_be_hmis
      return if data_source&.hmis?

      errors.add(:data_source, 'must be an HMIS data source')
    end

    def data_source_must_match_project_group
      return if data_source.blank? || project_group.blank?
      return if data_source_id == project_group.data_source_id

      errors.add(:project_group, 'must belong to the same data source')
    end
  end
end
