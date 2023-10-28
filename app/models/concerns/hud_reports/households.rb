###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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

    def hoh_age(household_id, date)
      return unless households[household_id]

      hoh_dob = households[household_id].detect { |hm| hm[:relationship_to_hoh] == 1 }&.try(:[], :dob)
      return unless hoh_dob

      GrdaWarehouse::Hud::Client.age(date: date, dob: hoh_dob)
    end

    private def get_hh_id(service_history_enrollment)
      service_history_enrollment.household_id || "#{service_history_enrollment.enrollment_group_id}*HH"
    end

    private def households
      calculate_households if @households.nil?
      @households
    end

    private def hoh_enrollments
      calculate_households if @hoh_enrollments.nil?
      @hoh_enrollments
    end

    # Chronic status should come from the HoH if they are chronically homeless
    # if not, use any other adult who is,
    # if no adults are either yes or no, use  self for adults, and the HoH enrollment for children
    # from glossary:
    # In cases where the head of household as well as all other adult household members have an indeterminate CH status (don’t know, refused, missing), any child household members should carry the same CH status as the head of household.
    # NOTE: Client CH status is only inherited if the client was present at the start of the enrollment.
    # per HUD guidance, the HoH should always be present for the entire stay, so we'll compare start dates to them
    # see AirTable Issue ID 30
    private def household_chronic_status(hh_id, client_id)
      household_members = households[hh_id]
      hoh = household_members.detect { |hm| hm[:relationship_to_hoh] == 1 }
      current_member = household_members.detect { |hm| hm[:client_id] == client_id }

      # HoH if they are chronically homeless
      return hoh if hoh.present? && hoh[:chronic_status] && hoh[:entry_date] == current_member[:entry_date]

      chronic_adult = household_members.detect do |hm|
        next false unless hm[:age].present?

        hm[:age] >= 18 && hm[:chronic_status] && hm[:entry_date] == current_member[:entry_date]
      end
      # if not, use any other adult who is (with the same entry date)
      return chronic_adult if chronic_adult.present?

      # if no adults are either yes or no, use self for adults
      return current_member if current_member[:age].present? && current_member[:age] >= 18
      # if the data is bad and we don't have an HoH, use our own record
      return current_member if hoh.blank?

      # and the HoH enrollment for children if HoH status is unknown
      return hoh if hoh[:chronic_detail].in?([:dk_or_r, :missing])

      current_member
    end

    private def calculate_move_in_date(hh_id, she)
      return nil unless she.move_in_date.present?

      move_in_date = she.move_in_date
      # If the move-in-date is valid, just use it
      return move_in_date if move_in_date >= she.first_date_in_program

      # If the client moved in before the entry date, and the HoH was present on the move-in date, use the
      # entry date as the move-in date.
      household_members = households[hh_id]
      hoh = household_members.detect { |hm| hm[:relationship_to_hoh] == 1 }
      return nil unless hoh.present?
      return she.first_date_in_program if hoh[:entry_date] <= move_in_date

      # Otherwise this move-in is completely invalid
      nil
    end

    private def calculate_households
      @hoh_enrollments ||= {}
      @households ||= {}

      @generator.client_scope.find_in_batches(batch_size: 100) do |batch|
        enrollments_by_client_id = clients_with_enrollments(batch)
        enrollments_by_client_id.each do |_, enrollments|
          enrollments.each do |enrollment|
            @hoh_enrollments[enrollment.client_id] = enrollment if enrollment.head_of_household?
            next unless enrollment&.enrollment&.client.present?

            date = [enrollment.first_date_in_program, @report.start_date].max
            age = GrdaWarehouse::Hud::Client.age(date: date, dob: enrollment.enrollment.client.DOB&.to_date)
            @households[get_hh_id(enrollment)] ||= []
            @households[get_hh_id(enrollment)] << {
              client_id: enrollment.client_id,
              source_client_id: enrollment.enrollment.client.id,
              dob: enrollment.enrollment.client.DOB,
              age: age,
              veteran_status: enrollment.enrollment.client.VeteranStatus,
              chronic_status: enrollment.enrollment.chronically_homeless_at_start?,
              chronic_detail: enrollment.enrollment.chronically_homeless_at_start,
              relationship_to_hoh: enrollment.enrollment.RelationshipToHoH,
              # Include dates for determining if someone was present at assessment date
              entry_date: enrollment.first_date_in_program,
              exit_date: enrollment.last_date_in_program,
            }.with_indifferent_access
          end
        end
        GC.start
      end
    end

    private def get_hoh_id(hh_id)
      households[hh_id]&.detect { |household| household[:relationship_to_hoh] == 1 }.try(:[], :client_id)
    end

    private def household_member_data(enrollment, _date = nil) # date is included for CE APR compatibility
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
      household_ages = ages_for(household_id, date)
      return :adults_and_children if adults?(household_ages) && children?(household_ages)
      return :adults_only if adults?(household_ages) && ! children?(household_ages) && ! unknown_ages?(household_ages)
      return :children_only if children?(household_ages) && ! adults?(household_ages) && ! unknown_ages?(household_ages)

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
