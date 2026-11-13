###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  # @see docs/features/warehouse/cohorts.md
  class CohortClient < GrdaWarehouseBase
    include TsqlImport
    acts_as_paranoid
    has_paper_trail

    belongs_to :cohort
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    has_many :cohort_client_notes
    has_many :cohort_client_changes, class_name: 'GrdaWarehouse::CohortClientChange'
    has_many :service_history_enrollments, through: :client

    validates_presence_of :cohort, :client

    delegate :name, to: :client

    # Visible to anyone who can see this cohort (cohorts don't consult ordinary
    # PII permissions), except an HMIS-restricted client, which is always blocked.
    # `mode: :download` additionally requires the org-wide `include_pii_in_detail_downloads`
    # toggle — the same distinction `User#reporting_policy_for_project`/`#reporting_policy_for_client`
    # make elsewhere, since a client visible on-screen in a cohort grid isn't necessarily meant to
    # be bulk-exportable.
    def pii_provider(user:, mode: :browse)
      allowed = case mode.to_sym
      when :download
        ::GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
      when :browse
        true
      else
        raise ArgumentError, "Bad mode #{mode}"
      end
      base_policy = allowed ? GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance : GrdaWarehouse::AuthPolicies::DenyPiiPolicy.instance
      policy = GrdaWarehouse::PiiProvider.restrict(base_policy, restricted: user.policy_context.client_restricted?(client_id))
      GrdaWarehouse::PiiProvider.new(client, policy: policy)
    end

    scope :active, -> do
      where(active: true)
    end

    scope :inactive, -> do
      where(active: false)
    end

    attr_accessor :reason

    def self.available_removal_reasons
      [
        'Housed',
        'Mistake',
        'Missing',
        'Not a veteran',
        'Deceased',
        'Inactive',
        'Unknown',
        'Other',
        'N/A',
      ]
    end
  end
end
