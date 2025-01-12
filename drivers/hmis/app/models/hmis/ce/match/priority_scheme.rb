
module Hmis::Ce::Match
  class PriorityScheme< GrdaWarehouseBase
    self.table_name = 'ce_match_priority_schemes'

    has_and_belongs_to_many :candidate_pools, class_name: 'Hmis::Ce::Match::ReferralRequirement', foreign_key: :candidate_policy_id, dependent: :destroy

    validates :name, presence: true
  end
end
