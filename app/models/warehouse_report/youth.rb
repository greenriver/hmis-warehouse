class WarehouseReport::Youth < OpenStruct
  include ArelHelper

  attr_accessor :start_date
  attr_accessor :end_date


  def group client_id
    case client_id
    when *homeless_youth_new_ids
      'New'
    when *homeless_youth_returning_ids
      'Returning'
    when *homeless_youth_prior_month_ids
      'Continuing'
    else
      'Unknown'
    end
  end

  def enrollments
    homeless_youth_scope.joins(:client).
      includes(enrollment: :exit)
  end

  def homeless_youth_new_ids
    @homeless_youth_new_ids ||= homeless_youth_ids - homeless_youth_prior_month_ids - homeless_youth_returning_ids
  end

  def homeless_youth_returning_ids
    @homeless_youth_returning_ids ||= homeless_youth_returning_scope.distinct.pluck(:client_id)
  end

  # check for any enrollments in the 5 years prior to the start date
  # where those are not enrolled in the prior month
  def homeless_youth_returning_scope
    prev_start = (self[:start_date] - 5.years).beginning_of_month
    prev_end = self[:start_date] - 1.day
    homeless_youth_scope.open_between(start_date: prev_start, end_date: prev_end).
      where(client_id: homeless_youth_scope.distinct.select(:client_id)).
      where.not(client_id: homeless_youth_prior_month_scope.distinct.select(:client_id))
  end

  # continuing enrollments
  def homeless_youth_prior_month_ids
    @homeless_youth_prior_month_ids ||= homeless_youth_prior_month_scope.distinct.pluck(:client_id)
  end

  def homeless_youth_prior_month_scope
    prev_start = (self[:start_date] - 1.months).beginning_of_month
    prev_end = prev_start.end_of_month
    homeless_youth_scope.open_between(start_date: prev_start, end_date: prev_end).
      where(client_id: homeless_youth_scope.distinct.select(:client_id))
  end

  def homeless_youth_ids
    @homeless_youth_ids ||= homeless_youth_scope.distinct.pluck(:client_id)
  end

  def homeless_youth_scope
    youth_scope.homeless.open_between(start_date: self[:start_date], end_date: self[:end_date])
  end

  def youth_scope
    GrdaWarehouse::ServiceHistoryEnrollment.entry.youth
  end

end