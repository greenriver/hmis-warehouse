###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectScorecard
  module GrantManagementAndFinancials
    extend ActiveSupport::Concern
    included do
      def spend_down_percentage
        return nil unless [amount_awarded, months_since_start, funds_expended].all?

        projected_amount = amount_awarded * (months_since_start / 12.0)
        (((projected_amount - funds_expended) / projected_amount) * 100).round
      end

      def spend_down_score
        score(spend_down_percentage.abs, 0..10, 11.15) if spend_down_percentage.present?
      end

      def budget_plus_match
        amount_awarded * 1.25 if amount_awarded.present?
      end

      def participants_in_psh
        return nil unless [total_persons_served, unsuccessful_exits, excluded_exits].all?

        total_persons_served - unsuccessful_exits - excluded_exits
      end

      def cost_per_participant
        return nil unless [budget_plus_match, participants_in_psh].all?

        (budget_plus_match / participants_in_psh).round
      end

      def cost_efficiency_score
        if project.psh?
          score(cost_per_participant, 0..8_999, 9_000..11_000)
        elsif project.rrh?
          score(cost_per_participant, 0..2_499, 2_500..5_400)
        end
      end

      def unspent_amount
        return nil unless [amount_awarded, funds_expended].all?

        amount_awarded - funds_expended
      end

      def percentage_recaptured
        return nil unless [unspent_amount, amount_awarded].all?

        ((unspent_amount / amount_awarded.to_f) * 100).round
      end

      def recaptured_score
        score(percentage_recaptured, 0..2, 3..5)
      end

      def pit_participation_score
        return 10 if pit_participation?
        return 0 unless pit_participation.nil?
      end

      def percentage_meetings_attended
        return nil unless [coc_meetings_attended, coc_meetings].all?

        ((coc_meetings_attended / coc_meetings.to_f) * 100).round
      end

      def meetings_attended_score
        score(percentage_meetings_attended, 75.., 50..74)
      end
    end
  end
end
