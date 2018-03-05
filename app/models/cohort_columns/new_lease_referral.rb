module CohortColumns
  class NewLeaseReferral < Base
    attribute :column, String, lazy: true, default: :new_lease_referral
    attribute :title, String, lazy: true, default: 'New Lease Referral'

    def default_input_type
      :select2
    end

    def available_options
      ['Submitted', 'Client Ineligible', 'Client Uninterested']
    end

  end
end
