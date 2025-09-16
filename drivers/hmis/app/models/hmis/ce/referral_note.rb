# frozen_string_literal: true

# Free-form notes a referral, optionally associated with a particular step
module Hmis::Ce
  class ReferralNote < GrdaWarehouseBase
    has_paper_trail
    acts_as_paranoid
    belongs_to :referral, class_name: 'Hmis::Ce::Referral'
    belongs_to :user, class_name: 'Hmis::User'
    belongs_to :wfe_step, class_name: 'Hmis::WorkflowExecution::Step', optional: true
  end
end
