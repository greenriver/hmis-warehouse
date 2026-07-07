###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  module Ce
    class DeleteCeMatchRule < Mutations::CleanBaseMutation
      argument :id, ID, required: true

      field :rule, Types::HmisSchema::CeMatchRule, null: true

      def resolve(id:)
        rule = Hmis::Ce::Match::Rule.find(id)
        access_denied! unless policy_for(rule, policy_type: :ce_match_rule).can_delete?

        rule.destroy!

        { rule: rule }
      end
    end
  end
end
