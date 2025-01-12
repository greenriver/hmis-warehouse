# Describes the eligibility requirements and prioritization for a client.

module Hmis::Ce::Match
  class Policy < GrdaWarehouseBase
    self.table_name = 'ce_match_policies'
    has_many :candidates, class_name: 'Hmis::Ce::Match::Candidate', foreign_key: :match_policy_id, dependent: :destroy
    has_many :opportunities, class_name: 'Hmis::Ce::Opportunity', dependent: :restrict_with_exception

    validates :name, presence: true
  end
end
