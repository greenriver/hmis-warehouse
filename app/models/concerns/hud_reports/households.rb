###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# require 'get_process_mem'
# Required concerns:
#   HudReports::Ages
#
# Required accessors:
#   a_t: Arel Type for the universe model
#   enrollment_scope: ServiceHistoryEnrollment scope for the enrollments included in the report
#   client_scope: Client scope for unique clients included in the report
#
# Required universe fields:
#   household_type: [:adults_only | :adults_and_children | :children_only | :unknown]
#   head_of_household: Boolean
#   head_of_household_id: Reference
#
module HudReports::Households
  extend ActiveSupport::Concern

  included do
    private def hoh_clause
      a_t[:head_of_household].eq(true)
    end

    private def adult_or_hoh_clause
      adult_clause.or(hoh_clause)
    end

    private def ages_for(household_id, date)
      return [] unless households[household_id]

      households[household_id].map { |client| GrdaWarehouse::Hud::Client.age(date: date, dob: client[:dob]) }
    end

    private def get_hh_id(service_history_enrollment)
      service_history_enrollment.household_id || "#{service_history_enrollment.enrollment_group_id}*HH"
    end

    private def households
      @households ||= {}.tap do |hh|
        enrollment_scope_without_preloads.preload(enrollment: :client).
          where(client_id: client_scope).find_in_batches(batch_size: 250) do |batch|
            # puts 'Household Batch: '
            # puts GetProcessMem.new.inspect
            batch.each do |enrollment|
              next unless enrollment.enrollment.client

              hh[get_hh_id(enrollment)] ||= []
              hh[get_hh_id(enrollment)] << {
                source_client_id: enrollment.enrollment.client.id,
                dob: enrollment.enrollment.client.DOB,
                veteran_status: enrollment.enrollment.client.VeteranStatus,
                chronic_status: enrollment.enrollment.chronically_homeless_at_start?,
                relationship_to_hoh: enrollment.enrollment.RelationshipToHoH,
              }.with_indifferent_access
            end
            GC.start
          end
      end
    end

    private def household_member_data(enrollment)
      # return nil unless enrollment[:head_of_household]

      households[enrollment.household_id] || []
    end

    # Note, you need to pass in a client because the date needs to be calculated
    private def household_adults(universe_client)
      return [] unless universe_client.household_members

      date = [universe_client.first_date_in_program, @report.start_date].max
      universe_client.household_members.select do |member|
        next false if member['dob'].blank?

        age = GrdaWarehouse::Hud::Client.age(date: date, dob: member['dob'].to_date)
        age.present? && age >= 18
      end
    end

    private def only_youth?(universe_client)
      youth_and_child_household_members(universe_client).count == universe_client.household_members.count
    end

    private def youth_and_child_household_members(universe_client)
      return [] unless universe_client.household_members

      date = [universe_client.first_date_in_program, @report.start_date].max
      universe_client.household_members&.select do |member|
        next false if member['dob'].blank?

        age = GrdaWarehouse::Hud::Client.age(date: date, dob: member['dob'].to_date)
        age.present? && age <= 24
      end
    end

    private def youth_child_members(universe_client)
      youth_and_child_household_members(universe_client).select do |member|
        member['relationship_to_hoh'] == 2
      end
    end

    private def youth_children?(universe_client)
      youth_child_members(universe_client).any?
    end

    private def youth_child_source_client_ids(universe_client)
      youth_child_members(universe_client).map { |member| member['source_client_id'] }
    end

    private def adult_source_client_ids(universe_client)
      household_adults(universe_client).map { |member| member['source_client_id'] }
    end

    private def youth_parent?(universe_client)
      universe_client.head_of_household && only_youth?(universe_client) && youth_children?(universe_client)
    end

    private def household_makeup(household_id, date)
      return :adults_and_children if adults?(ages_for(household_id, date)) && children?(ages_for(household_id, date))
      return :adults_only if adults?(ages_for(household_id, date)) && ! children?(ages_for(household_id, date)) && ! unknown_ages?(ages_for(household_id, date))
      return :children_only if children?(ages_for(household_id, date)) && ! adults?(ages_for(household_id, date)) && ! unknown_ages?(ages_for(household_id, date))

      :unknown
    end

    private def sub_populations
      {
        'Total' => Arel.sql('1=1'), # include everyone
        'Without Children' => a_t[:household_type].eq(:adults_only),
        'With Children and Adults' => a_t[:household_type].eq(:adults_and_children),
        'With Only Children' => a_t[:household_type].eq(:children_only),
        'Unknown Household Type' => a_t[:household_type].eq(:unknown),
      }
    end
  end
end
