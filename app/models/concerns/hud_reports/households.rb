###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    private def batch_size
      250
    end

    private def hoh_clause
      a_t[:head_of_household].eq(true)
    end

    private def hoh_or_spouse
      a_t[:relationship_to_hoh].in([1, 3])
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

    private def hoh_exit_date(household_id)
      return unless households[household_id]

      households[household_id].detect { |hm| hm[:relationship_to_hoh] == 1 }&.try(:[], :exit_date)
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
      # we couldn't find a household
      return false unless household_members.present?

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

      # if we have an indeterminate response for the child, use the hoh
      return hoh if current_member[:chronic_detail].in?([:dk_or_r, :missing])

      current_member
    end

    private def calculate_move_in_date(hh_id, she)
      move_in_date = she.move_in_date
      # If the move-in-date is valid, just use it
      return move_in_date if move_in_date.present? && move_in_date >= she.entry_date

      # Get HoH for further calculations
      household_members = households[hh_id]
      hoh = household_members.detect { |hm| hm[:relationship_to_hoh] == 1 }
      # HoH does not exist or does not have a move-in date - cannot do further calculations
      return nil unless hoh.present? && hoh[:move_in_date].present?

      # [Handling Housing Move-In Dates] - https://files.hudexchange.info/resources/documents/HMIS-Standard-Reporting-Terminology-Glossary-2024.pdf

      # Heads of household with [housing move-in dates] prior to their [project start dates] should have the [housing move-in dates] disregarded entirely.
      return nil unless hoh[:entry_date] <= hoh[:move_in_date]

      # When a household member was already in the household when they became housed (individual’s [project
      # start date] <= head of household’s [housing move-in date]), the head of household’s [housing move-in date]
      # should be used as the individual’s [housing move-in date]. If the household member exited before the
      # household moved into housing, they do not inherit this [housing move-in date].
      return hoh[:move_in_date] if (she.entry_date..she.exit_date).include?(hoh[:move_in_date])

      # When a household member joins the household after they are already housed (individual’s [project start
      # date] > head of household’s [housing move-in date]), the individual’s [project start date] should be used as
      # the individual’s [housing move-in date].
      return she.entry_date if she.entry_date > hoh[:move_in_date]

      # Otherwise this move-in is completely invalid
      nil
    end

    private def calculate_households
      @hoh_enrollments ||= {}
      @households ||= {}

      # NOTE: batch_size must match calculate_households in the class that includes this concern
      @generator.client_scope.find_in_batches(batch_size: batch_size) do |batch|
        enrollments_by_client_id = clients_with_enrollments(
          batch,
          scope: enrollment_scope_without_preloads,
          preloads: { enrollment: [:client, :disabilities_at_entry, :project] },
        )
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
              move_in_date: enrollment.move_in_date,
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

    # Per HUD:
    # https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recCDGtYIVXlTmAvk
    # . The glossary does not make reference to the "relationship to head of household" required to include a youth in this category. Q27b ("Parenting Youth") is a bit clearer in the following language: "Report all heads of household plus all adults (age 18 – 24) in the household in column B according to the age of the head of household (age < 18 on line 2, or 18-24 on line 3). Include all adults in the household regardless of [relationship to head of household],"
    private def youth_parent?(universe_client)
      age = universe_client.age
      adult = age.present? && age >= 18
      (universe_client.head_of_household || adult) && only_youth?(universe_client) && youth_children?(universe_client)
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
