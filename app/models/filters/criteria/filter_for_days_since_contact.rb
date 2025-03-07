# frozen_string_literal: true

class Filters::Criteria::FilterForDaysSinceContact < Filters::Criteria::Base
  def applies?
    input.days_since_contact_min.present? || input.days_since_contact_max.present?
  end

  # Filters for the given range of days since the last contact,
  # where contact is any of:
  # Enrollment.EntryDate
  # Assessment.AssessmentDate
  # Service.DateProvided
  # CurrentLivingSituation.InformationDate
  def apply(scope)
    scope = super(scope)
    # Common Table Expressions
    max_assessment_dates = max_date_per_warehouse_client_id_cte(
      join: { source: :direct_assessments },
      date_column: arel.as_t[:AssessmentDate],
      merge_class: GrdaWarehouse::Hud::Assessment,
    )
    max_service_dates = max_date_per_warehouse_client_id_cte(
      join: { source: :direct_services },
      date_column: arel.s_t[:DateProvided],
      merge_class: GrdaWarehouse::Hud::Service,
    )
    max_enrollment_dates = max_date_per_warehouse_client_id_cte(
      join: { source: :enrollments },
      date_column: arel.e_t[:EntryDate],
      merge_class: GrdaWarehouse::Hud::Enrollment,
    )
    max_cls_dates = max_date_per_warehouse_client_id_cte(
      join: { source: :direct_current_living_situations },
      date_column: arel.cls_t[:InformationDate],
      merge_class: GrdaWarehouse::Hud::CurrentLivingSituation,
    )
    range = input.days_since_contact_min..input.days_since_contact_max
    on_date = input.on
    # Find the IDs of the destination clients who meet the initial scope AND the filter
    inner_query = GrdaWarehouse::Hud::Client.destination.
      with(
        assessment_dates: max_assessment_dates,
        service_dates: max_service_dates,
        enrollment_dates: max_enrollment_dates,
        cls_dates: max_cls_dates,
      ).
      joins('INNER JOIN assessment_dates ON "Client"."id" = assessment_dates.destination_id').
      joins('INNER JOIN service_dates ON "Client"."id" = service_dates.destination_id').
      joins('INNER JOIN enrollment_dates ON "Client"."id" = enrollment_dates.destination_id').
      joins('INNER JOIN cls_dates ON "Client"."id" = cls_dates.destination_id').
      group(:id).
      select(
        arel.c_t[:id],
        Arel::Nodes::Subtraction.new(
          Arel::Nodes.build_quoted(on_date.to_fs(:db)),
          Arel.sql('MAX(GREATEST(assessment_dates.date, service_dates.date, enrollment_dates.date, cls_dates.date)) as days'),
        ),
      )

    filtered_client_ids = GrdaWarehouse::Hud::Client.unscoped.
      select(:id).
      from(inner_query, :inner_query).
      where('inner_query.days'.to_sym => range)
    # Then return the initial scope filtered down to those ids
    scope.where(client_id: filtered_client_ids)
  end

  protected

  def max_date_per_warehouse_client_id_cte(join:, date_column:, merge_class:)
    p_ids = input.personal_ids_for_days_since_contact_calculations
    query = GrdaWarehouse::WarehouseClient.
      joins(**join)
    query = query.merge(merge_class.where(PersonalID: p_ids)) if p_ids.any?
    query.group(:destination_id).
      select(
        :destination_id,
        arel.nf(
          'MAX',
          [date_column],
        ).as('date'),
      )
  end
end
