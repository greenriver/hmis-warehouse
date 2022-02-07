###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
        return nil if projected_amount.zero?

        (((projected_amount - funds_expended) / projected_amount) * 100).round
      end

      def spend_down_score
        score(spend_down_percentage.abs, 0..10, 11..15) if spend_down_percentage.present?
      end

      def participants_in_psh
        return nil unless [total_persons_served, unsuccessful_exits, excluded_exits].all?

        total_persons_served - unsuccessful_exits - excluded_exits
      end

      def cost_per_participant
        return nil unless [budget_plus_match, participants_in_psh].all?
        return nil unless participants_in_psh.positive?

        (budget_plus_match / participants_in_psh).round
      end

      def cost_efficiency_score
        return 0 if expansion_year

        # Note: per 5/3/2021 request, treat SH as PSH
        if key_project.psh? || key_project.sh?
          score(cost_per_participant, 0..8_999, 9_000..11_000)
        elsif key_project.rrh?
          score(cost_per_participant, 0..2_499, 2_500..5_400)
        end
      end

      def prior_unspent_amount
        return nil unless [prior_amount_awarded, prior_funds_expended].all?

        prior_amount_awarded - prior_funds_expended
      end

      def percentage_recaptured
        return nil unless [prior_unspent_amount].all?
        return nil if prior_amount_awarded.zero?

        ((prior_unspent_amount / prior_amount_awarded.to_f) * 100).round
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
        return nil if coc_meetings.zero?

        ((coc_meetings_attended / coc_meetings.to_f) * 100).round
      end

      def meetings_attended_score
        score(percentage_meetings_attended, 75..Float::INFINITY, 50..74)
      end
    end
  end
end
