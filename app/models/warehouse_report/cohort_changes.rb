class WarehouseReport::CohortChanges < OpenStruct
  include ArelHelper

  attr_accessor :start_date
  attr_accessor :end_date
  attr_accessor :cohort_id

  def start_date
    self[:start_date]
  end

  def end_date
    self[:end_date]
  end
  
  def cohort_id
    self[:cohort_id]
  end
  

  def group client_id
    case client_id
    when *new_ids
      'New'
    when *returning_ids
      'Returning'
    when *prior_month_ids
      'Continuing'
    else
      'Unknown'
    end
  end

  def active_clients
    GrdaWarehouse::Hud::Client.where(
      id: enrollment_scope.joins(:cohort_client).select(c_client_t[:client_id].to_sql)
    )
  end

  def cohort_enrollments
    enrollment_scope.joins(cohort_client: :client)

  end

  def new_ids
    @new_ids ||= client_ids - prior_month_ids - returning_ids
  end

  def returning_ids
    @returning_ids ||= returning_scope.distinct.pluck(c_client_t[:client_id].to_sql)
  end

  # check for any enrollments in the 5 years prior to the start date
  # where those are not enrolled in the prior month
  def returning_scope
    prev_start = (self[:start_date] - 5.years).beginning_of_month
    prev_end = self[:start_date] - 1.day
    cohort_scope.on_cohort_between(start_date: prev_start, end_date: prev_end).
      where(c_client_t[:client_id].in(client_ids)).
      where.not(c_client_t[:client_id].in(prior_month_ids))
  end

  # continuing enrollments
  def prior_month_ids
    @prior_month_ids ||= prior_month_scope.distinct.pluck(c_client_t[:client_id].to_sql)
  end

  def prior_month_scope
    prev_start = (self[:start_date] - 1.months).beginning_of_month
    prev_end = prev_start.end_of_month
    cohort_scope.on_cohort_between(start_date: prev_start, end_date: prev_end).
      where(c_client_t[:client_id].in(client_ids))
  end

  def client_ids
    @client_ids ||= enrollment_scope.distinct.pluck(c_client_t[:client_id].to_sql)
  end

  def enrollment_scope
    cohort_scope.on_cohort_between(start_date: self[:start_date], end_date: self[:end_date])
  end

  def cohort_scope
    GrdaWarehouse::CombinedCohortClientChange.on_cohort(self[:cohort_id]).joins(:cohort_client)
  end

end