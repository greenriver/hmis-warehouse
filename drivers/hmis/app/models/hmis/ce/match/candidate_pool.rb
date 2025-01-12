# Describes the eligibility requirements and prioritization for a client.

module Hmis::Ce::Match
  class CandidatePolicy < GrdaWarehouseBase
    self.table_name = 'ce_match_candidate_pools'
    has_many :candidates, class_name: 'Hmis::Ce::Match::Candidate', foreign_key: :candidate_policy_id, dependent: :destroy
    has_and_belongs_to_many :requirements, class_name: 'Hmis::Ce::Match::ReferralRequirement', foreign_key: :candidate_policy_id, dependent: :destroy
    has_many :opportunities, class_name: 'Hmis::Ce::Opportunity', dependent: :restrict_with_exception

    validates :name, presence: true


  end
end
