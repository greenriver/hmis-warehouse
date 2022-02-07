###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Api::Health::Claims::Patients
  class TopIpConditionsController < BaseController
    def load_data
      # @data = scope.order(sdh_pct: :desc).
      #   select(:description, :sdh_pct).
      #   distinct.
      #   limit(5).
      #   map do |row|
      #   row.attributes.with_indifferent_access.except(:id, :medicaid_id, :rank)
      # end
      @data = scope.order(indiv_pct: :desc).
        select(:description, :indiv_pct, :sdh_pct).
        distinct.
        limit(5).
        map do |row|
        row.attributes.with_indifferent_access.except(:id, :medicaid_id, :rank)
      end
    end

    def source
      ::Health::Claims::TopIpConditions
    end
  end
end
