class WarehouseReport::CasApr < OpenStruct
  include ArelHelper

  attr_accessor :start_date
  attr_accessor :end_date

  def total_households
    unique_households.count + unique_non_hmis_households.count
  end

  def total_families
    unique_households.family.count + unique_non_hmis_households.family.count
  end

  def total_individuals
    unique_households.individuals.count + unique_non_hmis_households.individuals.count
  end

  def total_youth
    unique_households.individuals.youth.count + unique_non_hmis_households.individuals.youth.count
  end

  def unique_households
    GrdaWarehouse::CasAvailability.
      available_between(start_date: self[:start_date], end_date: self[:end_date]).
      distinct.
      select(:client_id)
  end

  def unique_non_hmis_households
    GrdaWarehouse::CasNonHmisClientHistory.
      available_between(start_date: self[:start_date], end_date: self[:end_date]).
      distinct.
      select(:cas_client_id)
  end

  # unique clients on ProviderOnly route
  def referred_to_rrh
    GrdaWarehouse::CasReport.where(match_route: 'Provider Only Route').
      started_between(start_date: self[:start_date], end_date: self[:end_date]).
      distinct.
      select(:client_id)
  end

  # matches that have progressed past the initial DND review phase
  def referred_to_psh
    GrdaWarehouse::CasReport.where(match_route: 'Default Match Route').
      started_between(start_date: self[:start_date], end_date: self[:end_date]).
      distinct.
      select(:client_id)
  end

  def declined
    cr_t = GrdaWarehouse::CasReport.arel_table
    GrdaWarehouse::CasReport.
      started_between(start_date: self[:start_date], end_date: self[:end_date]).
      where(terminal_status: 'Rejected').
      where.not(cr_t[:decline_reason].matches('%eligible%')).
      distinct.
      select(:client_id)
  end

  def ineligible
    cr_t = GrdaWarehouse::CasReport.arel_table
    GrdaWarehouse::CasReport.
      started_between(start_date: self[:start_date], end_date: self[:end_date]).
      where(terminal_status: 'Rejected').
      where(cr_t[:decline_reason].matches('%eligible%')).
      distinct.
      select(:client_id)
  end

  # difference between those who initiated a match and those who were available
  def unable_to_refer
    total_households - GrdaWarehouse::CasReport.
      started_between(start_date: self[:start_date], end_date: self[:end_date]).
      distinct.
      select(:client_id).count
  end


  def match_dates
    report_columns = [:match_id, :match_route, :match_started_at, :updated_at, :terminal_status]
    matches = GrdaWarehouse::CasReport.
      started_between(start_date: self[:start_date], end_date: self[:end_date]).
      where.not(terminal_status: 'In Progress').
      where(current_step: true).
      order(:match_started_at).
      pluck(*report_columns).map do |row|
        Hash[report_columns.zip(row)]
      end
    housed_dates = GrdaWarehouse::CasHoused.where(match_id: matches.map{|m| m[:match_id]}).pluck(:match_id, :housed_on).to_h
    matches.each do |row|
      row[:housed_on] = housed_dates.try(:[], row[:match_id])
    end
    return matches
  end
end