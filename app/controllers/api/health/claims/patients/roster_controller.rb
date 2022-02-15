###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Api::Health::Claims::Patients
  class RosterController < BaseController
    def load_data
      @data = begin
        client_roster = scope.first
        individual = {
          name: @patient.client.name,
        }.merge(
          client_roster.
          attributes.with_indifferent_access.except(:id, :medicaid_id, :last_name, :first_name),
        )

        sums = Hash.new(0)
        counts = Hash.new(0)
        meta = [sums, counts]
        source.all.each do |row|
          metrics = row.attributes.with_indifferent_access.
            slice(:norm_risk_score, :mbr_months, :total_ty, :ed_visits, :acute_ip_admits, :average_days_to_readmit)
          metrics.each_with_object(meta) do |client, (i_sums, i_counts)|
            i_sums[client.first] += client.last || 0
            i_counts[client.first] += 1 if client.last.present?
          end
        end
        sdh = sums.each do |metric, total|
          sums[metric] = (total.to_f / counts[metric])&.round(2)
        end
        {
          individual: individual,
          sdh: sdh,
        }
      end
    end

    def source
      ::Health::Claims::Roster
    end
  end
end
