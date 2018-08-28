module CohortColumns
  class NewLeaseReferral < Select
    attribute :column, String, lazy: true, default: :new_lease_referral
    attribute :title, String, lazy: true, default: 'New Lease Referral'

  end
end
