module CohortColumns
  class NewLeaseReferral < Select
    attribute :column, String, lazy: true, default: :new_lease_referral
    attribute :translation_key, String, lazy: true, default: 'New Lease Referral'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
