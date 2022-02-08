###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReport::CasDeclines < OpenStruct
  include ArelHelper
  attr_accessor :start_date
  attr_accessor :end_date

  def initialize(start_date:, end_date:)
    @start_date = start_date
    @end_date = end_date + 1.day # needed to catch starts and ends on the end date
  end

  def reasons
    @reasons ||= (declines + cancels).map do |row|
      reason = row.decline_reason || row.administrative_cancel_reason
      reason.squish.gsub(/Other.*/, 'Other').strip
    end.each_with_object(Hash.new(0)) do |reason, counts|
      counts[reason] += 1
    end.sort_by(&:last).reverse
  end

  def declines
    @declines ||= report_source.declined.
      started_between(start_date: start_date, end_date: end_date)
  end

  def declines_by_agency
    @declines_by_agency ||= declines.distinct.
      group(:program_name, :sub_program_name).
      count(:match_id)
  end

  def cancels
    @cancels ||= report_source.canceled_between(
      start_date: start_date,
      end_date: end_date,
    )
  end

  def cancels_by_agency
    @cancels_by_agency ||= cancels.distinct.
      group(:program_name, :sub_program_name).
      count(:match_id)
  end

  def referrals_by_agency
    @referrals_by_agency ||= report_source.started_between(start_date: start_date, end_date: end_date).
      distinct.
      group(:program_name, :sub_program_name).
      order(:program_name, :sub_program_name).
      count(:match_id)
  end

  def all_steps
    @all_steps ||= report_source.
      where(match_id: declines.pluck(:match_id) + cancels.pluck(:match_id)).
      order(decision_order: :asc).
      group_by(&:match_id)
  end

  def clients
    @clients ||= Cas::Client.distinct.
      where(id: declines.pluck(:cas_client_id) + cancels.pluck(:cas_client_id)).
      index_by(&:id)
  end

  def report_source
    GrdaWarehouse::CasReport
  end
end
