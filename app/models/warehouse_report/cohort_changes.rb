###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReport::CohortChanges < OpenStruct
  include ArelHelper
  attr_writer :start_date
  attr_writer :end_date
  attr_writer :cohort_id

  def start_date
    self[:start_date]
  end

  def end_date
    self[:end_date]
  end

  def cohort_id
    self[:cohort_id]
  end

  def group(client_id)
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

  def average_time_to_housing
    times = details[:time_to_housings]
    return 'No one housed' unless times.any?

    times.sum.to_f / times.count
  end

  def more_than_90_days_since_vispdat
    client_ids.count - details[:assessment_within_90_days]
  end

  def details
    @details ||= begin
      sleeping_locations = {}
      exit_destinations = {}
      vispdat_scores = {
        '0-3' => 0,
        '4-7' => 0,
        '8-17' => 0,
        'unknown' => 0,
      }
      time_to_housings = []
      assessment_within_90_days = 0
      GrdaWarehouse::CohortClient.where(id: enrollment_scope.distinct.select(:cohort_client_id)).each do |cc|
        client_id = cc.client_id
        vispdat = vispdat_for(client_id)
        c_en = cohort_change_for(client_id)
        # Sleeping questions
        sleeping_key = cc.sleeping_location&.strip.presence || 'Unknown'
        sleeping_locations[sleeping_key] ||= {
          count: 0,
          of_color: 0,
          white: 0,
          lgbtq: 0,
          heterosexual: 0,
          gender_diverse: 0,
          cisgender: 0,
        }
        sleeping_locations[sleeping_key][:count] += 1
        sleeping_locations[sleeping_key][race_bucket(client_id)] += 1
        sleeping_locations[sleeping_key][gender_bucket(client_id)] += 1
        sleeping_locations[sleeping_key][lgbtq_bucket(cc.lgbtq)] += 1

        # Exit destination questions
        destination_key = cc.exit_destination&.strip.presence || 'No Destination'
        exit_destinations[destination_key] ||= {
          count: 0,
          of_color: 0,
          white: 0,
          lgbtq: 0,
          heterosexual: 0,
          gender_diverse: 0,
          cisgender: 0,
        }
        exit_destinations[destination_key][:count] += 1
        exit_destinations[destination_key][race_bucket(client_id)] += 1
        exit_destinations[destination_key][gender_bucket(client_id)] += 1
        exit_destinations[destination_key][lgbtq_bucket(cc.lgbtq)] += 1

        vispdat_scores[vispdat_bucket(client_id)] += 1

        assessment_within_90_days += 1 if vispdat.present? && vispdat.submitted_at.present? && (self[:end_date] - vispdat.submitted_at.to_date) < 90

        time_to_housings << (c_en.exit_date.to_date - vispdat.submitted_at.to_date).to_i if vispdat.present? && vispdat.submitted_at.present? && c_en.exit_date.present? && c_en.change_reason&.downcase == 'housed'
      end
      {
        sleeping_locations: sleeping_locations,
        exit_destinations: exit_destinations,
        vispdat_scores: vispdat_scores,
        assessment_within_90_days: assessment_within_90_days,
        time_to_housings: time_to_housings,
      }
    end
  end

  def lgbtq_bucket(lgbtq)
    case lgbtq&.downcase
    when 'yes'
      :lgbtq
    else
      :heterosexual
    end
  end

  def vispdat_bucket(client_id)
    vispdat_score = vispdat_for(client_id)&.score || 'unknown'
    case vispdat_score
    when *(0..3).to_a
      '0-3'
    when *(4..7).to_a
      '4-7'
    when *(8..17).to_a
      '8-17'
    else
      'unknown'
    end
  end

  # most recent completed vispdat per client by client_id
  def vispdat_for(client_id)
    @vispdat ||= GrdaWarehouse::Vispdat::Base.completed.
      order(submitted_at: :asc).
      where(client_id: enrollment_scope.select(:client_id)).
      select(:client_id, :score, :submitted_at).
      index_by(&:client_id)

    @vispdat[client_id]
  end

  def cohort_change_for(client_id)
    @cohort_change_for ||= enrollment_scope.order(id: :asc).index_by(&:client_id)
    @cohort_change_for[client_id]
  end

  def gender_bucket(client_id)
    gender_ids = client_from_id(client_id).gender_multi - [8, 9, 99]
    return :gender_diverse if gender_ids.count > 1
    return :gender_diverse if (gender_ids & [2, 3, 4, 5, 6]).any?

    :cisgender
  end

  def race_bucket(client_id)
    case client_cache.race_string(scope_limit: active_clients, destination_id: client_id)
    when 'White'
      :white
    else
      :of_color
    end
  end

  def client_from_id(client_id)
    clients_by_id[client_id]
  end

  def client_cache
    @client_cache ||= GrdaWarehouse::Hud::Client.new
  end

  def clients_by_id
    @clients_by_id ||= active_clients.index_by(&:id)
  end

  def active_clients
    GrdaWarehouse::Hud::Client.where(id: enrollment_scope.select(:client_id))
  end

  def cohort_enrollments
    enrollment_scope.joins(:client).includes(:cohort_client)
  end

  def new_ids
    @new_ids ||= client_ids - prior_month_ids - returning_ids
  end

  def returning_ids
    @returning_ids ||= returning_scope.distinct.pluck(:client_id)
  end

  # check for any enrollments in the 5 years prior to the start date
  # where those are not enrolled in the prior month
  def returning_scope
    prev_start = (self[:start_date] - 5.years).beginning_of_month
    prev_end = self[:start_date] - 1.day
    cohort_scope.on_cohort_between(start_date: prev_start, end_date: prev_end).
      where(client_id: enrollment_scope.distinct.select(:client_id)).
      where.not(client_id: prior_month_scope.distinct.select(:client_id))
  end

  # continuing enrollments
  def prior_month_ids
    @prior_month_ids ||= prior_month_scope.distinct.pluck(:client_id)
  end

  def prior_month_scope
    prev_start = (self[:start_date] - 1.months).beginning_of_month
    prev_end = prev_start.end_of_month
    cohort_scope.on_cohort_between(start_date: prev_start, end_date: prev_end).
      where(client_id: enrollment_scope.distinct.select(:client_id))
  end

  def client_ids
    @client_ids ||= enrollment_scope.distinct.pluck(:client_id)
  end

  def enrollment_scope
    cohort_scope.on_cohort_between(start_date: self[:start_date], end_date: self[:end_date])
  end

  def cohort_scope
    GrdaWarehouse::CombinedCohortClientChange.on_cohort(self[:cohort_id])
  end
end
