###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Api::Health::Claims
  class ClaimsVolumeController < BaseController
    include ArelHelper

    def load_data
      a_t = source.arel_table
      @data = source.order(year: :asc, month: :asc).
        group(:year, :month).pluck(
          :year,
          :month,
          nf('SUM', [a_t[:ip]]).to_sql,
          nf('SUM', [a_t[:emerg]]).to_sql,
          nf('SUM', [a_t[:respite]]).to_sql,
          nf('SUM', [a_t[:op]]).to_sql,
          nf('SUM', [a_t[:rx]]).to_sql,
          nf('SUM', [a_t[:other]]).to_sql,
          nf('SUM', [a_t[:total]]).to_sql,
        ).map do |year, month, ip, emerg, respite, op, rx, other, total| # rubocop:disable Metrics/ParameterLists
          {
            date: "#{year}-#{month}-01",
            ip: ip,
            emerg: emerg,
            respite: respite,
            op: op,
            rx: rx,
            other: other,
            total: total,
          }
        end

      # @data = group_by_date_and_sum_by_category(source.order(year: :asc, month: :asc))
    end

    def source
      ::Health::Claims::ClaimsVolume
    end
  end
end
