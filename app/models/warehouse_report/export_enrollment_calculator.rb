###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class WarehouseReport::ExportEnrollmentCalculator < OpenStruct
  include ArelHelper
  attr_accessor :batch_scope
  attr_accessor :filter

  def initialize(batch_scope:, filter:)
    @batch_scope = batch_scope
    @filter = filter
  end

  def clients
    @batch_scope
  end

  def client_disabled?(client)
    @disabled_clients ||= GrdaWarehouse::Hud::Client.disabled_client_scope.where(id: clients.select(:id)).pluck(:id)
    @disabled_clients.include?(client.id)
  end

  def exit_for_client(client)
    @exits ||= begin
      exits = {}
      clients.joins(:source_exits).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
        merge(GrdaWarehouse::Hud::Exit.where(ex_t[:ExitDate].lteq(filter.last))).
        find_each do |client_record|
          exits[client_record.id] = client_record.source_exits.max_by(&:ExitDate)
        end
      exits
    end
    @exits[client.id]
  end

  def enrollment_for_client(client)
    enrollments(clients)[client.id]
  end

  def enrollments(clients)
    @enrollments ||= begin
      enrollments = {}
      clients.joins(source_enrollments: :project).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
        find_each do |client_record|
          enrollments[client_record.id] = client_record.source_enrollments.max_by(&:EntryDate)
        end
      enrollments
    end
  end

  def income_for_client(client)
    @incomes ||= begin
      incomes = {}
      clients.joins(:source_income_benefits).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
        find_each do |client_record|
          incomes[client_record.id] = client_record.source_income_benefits.max_by(&:InformationDate)
        end
      incomes
    end
    @incomes[client.id]
  end

  def physical_disability_for_client(client)
    @physical_disabilities ||= begin
      physical_disabilities = {}
      clients.joins(:source_disabilities).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
        find_each do |client_record|
          physical_disabilities[client_record.id] = client_record.source_disabilities.
            merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
            physical.
            max_by(&:InformationDate)
        end
      physical_disabilities
    end
    @physical_disabilities[client.id]
  end

  def developmental_disability_for_client(client)
    @developmental_disabilities ||= begin
      developmental_disabilities = {}
      clients.joins(:source_disabilities).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
        find_each do |client_record|
          developmental_disabilities[client_record.id] = client_record.source_disabilities.
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
          developmental.
          max_by(&:InformationDate)
        end
      developmental_disabilities
    end
    @developmental_disabilities[client.id]
  end

  def chronic_disability_for_client(client)
    @chronic_disabilities ||= begin
      chronic_disabilities = {}
      clients.joins(:source_disabilities).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
        find_each do |client_record|
          chronic_disabilities[client_record.id] = client_record.source_disabilities.
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
          chronic.
          max_by(&:InformationDate)
        end
      chronic_disabilities
    end
    @chronic_disabilities[client.id]
  end

  def hiv_disability_for_client(client)
    @hiv_disabilities ||= begin
      hiv_disabilities = {}
      clients.joins(:source_disabilities).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
        find_each do |client_record|
          hiv_disabilities[client_record.id] = client_record.source_disabilities.
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
          hiv.
          max_by(&:InformationDate)
        end
      hiv_disabilities
    end
    @hiv_disabilities[client.id]
  end

  def mental_disability_for_client(client)
    @mental_disabilities ||= begin
      mental_disabilities = {}
      clients.joins(:source_disabilities).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
        find_each do |client_record|
          mental_disabilities[client_record.id] = client_record.source_disabilities.
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
          mental.
          max_by(&:InformationDate)
        end
      mental_disabilities
    end
    @mental_disabilities[client.id]
  end

  def substance_disability_for_client(client)
    @substance_disabilities ||= begin
      substance_disabilities = {}
      clients.joins(:source_disabilities).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
        find_each do |client_record|
          substance_disabilities[client_record.id] = client_record.source_disabilities.
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
          substance.
          max_by(&:InformationDate)
        end
      substance_disabilities
    end
    @substance_disabilities[client.id]
  end

  def health_for_client(client)
    @healths ||= begin
      healths = {}
      clients.joins(:source_health_and_dvs).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
        find_each do |client_record|
          healths[client_record.id] = client_record.source_health_and_dvs.max_by(&:InformationDate)
        end
      healths
    end
    @healths[client.id]
  end

  def education_for_client(client)
    @educations ||= begin
      educations = {}
      clients.joins(:source_employment_educations).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
        find_each do |client_record|
          educations[client_record.id] = client_record.source_employment_educations.max_by(&:InformationDate)
        end
      educations
    end
    @educations[client.id]
  end

  def vispdat_for_client(client)
    @vispdats ||= begin
      vispdats = {}
      clients.joins(:vispdats).
        merge(GrdaWarehouse::Vispdat::Base.completed.where(submitted_at: filter.range)).
        find_each do |client_record|
          vispdats[client_record.id] = client_record.vispdats.completed.max_by(&:submitted_at)
        end
      vispdats
    end
    @vispdats[client.id]
  end

  def days_homeless(client)
    @days_homeless ||= begin
      clients.joins(:processed_service_history).pluck(wcp_t[:client_id], wcp_t[:days_homeless_last_three_years]).to_h
    end
    @days_homeless[client.id] || 0
  end

  def pregnancy_status_for(client)
    HUD.no_yes_reasons_for_missing_data(health_and_dv_for(client)&.PregnancyStatus)
  end

  def health_and_dv_for(client)
    @health_and_dvs ||= begin
      health_and_dvs = {}
      clients.joins(:source_health_and_dvs).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(filter)).
        find_each do |client_record|
          health_and_dvs[client_record.id] = client_record.source_health_and_dvs.max_by(&:InformationDate)
        end
      health_and_dvs
    end
    @health_and_dvs[client.id]
  end

  def disabled_and_imparing?(client)
    @disabled_and_impairing ||= begin
      disabled_client_ids = clients.chronically_disabled(filter.end).pluck(:id)
    end
    @disabled_and_impairing.include?(client.id)
  end

  def episode_counts_past_3_years_for(client)
    client.homeless_episodes_between(
      start_date: filter.end - 3.years,
      end_date: filter.end,
      residential_enrollments: residential_enrollments_for(client),
      chronic_enrollments: chronic_enrollments_for(client),
    )
  end

  def episode_length_for(client)
    episodes = client.length_of_episodes(
      start_date: filter.end - 3.years,
      end_date: filter.end,
      residential_enrollments: residential_enrollments_for(client),
      chronic_enrollments: chronic_enrollments_for(client),
    )
    return unless episodes.present?

    episodes.last[:length]
  end

  def residential_enrollments_for(client)
    @residential_enrolments_for ||= begin
      GrdaWarehouse::ServiceHistoryEnrollment.residential.
      entry.
      open_between(start_date: filter.start, end_date: filter.end).
      where(client_id: clients.select(:id)).
      order(first_date_in_program: :asc).
      group_by(&:client_id)
    end
    @residential_enrolments_for[client.id]
  end

  def chronic_enrollments_for(client)
    @chronic_enrollments_for ||= begin
      GrdaWarehouse::ServiceHistoryEnrollment.
      hud_homeless(chronic_types_only: true).
      entry.
      open_between(start_date: filter.start, end_date: filter.end).
      where(client_id: clients.select(:id)).
      order(first_date_in_program: :asc).
      group_by(&:client_id)
    end
    @chronic_enrollments_for[client.id]
  end

  def household_size_for(client)
    @household_size_for ||= begin
      sizes = {}
      enrollment_ids = enrollments(clients).values.map(&:id)
      GrdaWarehouse::ServiceHistoryEnrollment.joins(:enrollment).
        merge(GrdaWarehouse::Hud::Enrollment.where(id: enrollment_ids)).
        pluck(:client_id, :other_clients_over_25, :other_clients_under_18, :other_clients_between_18_and_25).
        each do |client_id, *counts|
          # NOTE: "other clients" counts don't count this client
          sizes[client_id] = counts.sum + 1
        end
      sizes
    end
    @household_size_for[client.id]
  end

  # Was this client's last exit to a Permanent Destination but followed by an entry into SO, ES, SH?
  def returned?(client)
    exit_enrollment = exit_for_client(client)
    return unless exit_enrollment
    return unless HUD.permanent_destinations.include?(exit_enrollment.Destination)

    chronic_enrollments_for(client)&.
      select{|e| exit_enrollment.last_date_in_program < e.first_date_in_program}&.any?
  end
end
