###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasClientData
  extend ActiveSupport::Concern
  included do
    # A hook/wrapper to enable easily overriding how we get data for a given project client column
    # To use this efficiently, you'll probably want to preload a handful of data, see push_clients_to_cas.rb
    def value_for_cas_project_client(column)
      case column
      when :hiv_positive, :meth_production_conviction, :family_member
        send("determine_#{column}")
      else
        # by default, just attempt to fetch the data from the client
        send(column)
      end
    end

    private def determine_hiv_positive
      return hiv_positive if hiv_positive

      most_recent_pathways_or_rrh_assessment.
        question_matching_requirement('c_housing_HIV', '1').
        present?
    end

    private def determine_meth_production_conviction
      return meth_production_conviction if meth_production_conviction

      most_recent_pathways_or_rrh_assessment.
        question_matching_requirement('c_transfer_barrier_meth', '1').
        present?
    end

    private def determine_family_member
      return family_member if family_member

      response = most_recent_pathways_or_rrh_assessment.
        question_matching_requirement('c_additional_household_members')
      response&.AssessmentAnswer&.to_i&.positive?
    end
  end
end
