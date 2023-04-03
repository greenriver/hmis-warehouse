###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/boston-cas/blob/production/LICENSE.md
###

class CasAccess::Reporting::Decisions < CasBase
  include ArelHelper
  self.table_name = :reporting_decisions

  belongs_to :client, foreign_key: :cas_client_id, class_name: 'CasAccess::Client'
  belongs_to :match, class_name: 'CasAccess::ClientOpportunityMatch'

  scope :started_between, ->(range) do
    where(match_started_at: range.begin.beginning_of_day .. range.end.end_of_day)
  end

  scope :ended_between, ->(range) do
    terminated.
      where(updated_at: (range.begin.beginning_of_day .. range.end.end_of_day))
  end

  scope :open_between, ->(range) do
    at = arel_table
    # Excellent discussion of why this works:
    # http://stackoverflow.com/questions/325933/determine-whether-two-date-ranges-overlap
    d_1_start = range.begin.beginning_of_day # these are timestamps
    d_1_end = range.end.end_of_day # these are timestamps
    d_2_start = at[:match_started_at]
    d_2_end = at[:updated_at]
    # Currently does not count as an overlap if one starts on the end of the other
    where(d_2_end.gteq(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lteq(d_1_end)))
  end

  scope :on_route, ->(route_name) do
    where(match_route: route_name)
  end

  scope :program_type, ->(limit) do
    where(program_type: limit)
  end

  scope :associated_with_agency, ->(limit) do
    # joins are hard through polymorphic associations...
    program_names = EntityViewPermission.where(entity_type: 'Program', editable: true, agency_id: limit).
      map { |p| p.entity.name }
    where(program_name: program_names)
  end

  scope :current_step, -> do
    where(current_step: true)
  end

  # Only steps that actually took place
  # this is an approximation, where the updated timestamp is more than 9 seconds
  # after the created timestamp
  scope :activated, -> do
    where(
      Arel::Nodes::Subtraction.new(
        r_d_t[:updated_at].extract(:epoch),
        r_d_t[:created_at].extract(:epoch),
      ).gt(9),
    )
  end

  IN_PROGRESS = ['In Progress', 'Stalled'].freeze

  scope :in_progress, -> do
    where(terminal_status: IN_PROGRESS)
  end

  scope :ongoing_not_stalled, -> do
    where(current_status: 'In Progress')
  end

  scope :stalled, -> do
    where(current_status: 'Stalled')
  end

  scope :terminated, -> do
    where.not(terminal_status: IN_PROGRESS)
  end

  scope :success, -> do
    where(terminal_status: 'Success')
  end

  scope :unsuccessful, -> do
    where(terminal_status: ['Pre-empted', 'Rejected'])
  end

  scope :has_reason, ->(reason) do
    where(decline_reason: reason).
      or(where(administrative_cancel_reason: reason))
  end

  # This filters the decisions to ones with a reason field, but does not otherwise narrow the scope
  scope :has_a_reason, -> do
    where.not(decline_reason: nil).
      or(where.not(administrative_cancel_reason: nil))
  end

  scope :preempted, -> do
    where(terminal_status: 'Pre-empted')
  end

  scope :declined, -> do
    where(terminal_status: 'Declined')
  end

  scope :rejected, -> do
    where(terminal_status: 'Rejected')
  end

  def self.match_routes
    distinct.order(match_route: :asc).pluck(:match_route)
  end
end
