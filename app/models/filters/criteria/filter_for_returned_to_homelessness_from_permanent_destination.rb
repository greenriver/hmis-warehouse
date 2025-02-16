class Filters::Criteria::FilterForReturnedToHomelessnessFromPermanentDestination < Filters::Criteria::Base
  def applies? = input.returned_to_homelessness_from_permanent_destination

  def apply(scope)
    visible_enrollments = filter_for_user_access(scope)
    exits = visible_enrollments.
      select(:id, :client_id, :last_date_in_program, :destination).
      joins(enrollment: :exit).
      ended_between(start_date: input.start - 2.years, end_date: input.start).
      define_window(:client_window).
      partition_by(:client_id, order_by: { last_date_in_program: :desc }).
      select_window(:row_number, over: :client_window, as: :row_id)
    client_ids_with_recent_permanent_exits = GrdaWarehouse::ServiceHistoryEnrollment.from(exits).
      where("row_id = 1 and destination in (#{HudUtility2024.permanent_destinations.join(', ')})")

    scope.homeless.where(client_id: client_ids_with_recent_permanent_exits.select(:client_id))
  end
end
