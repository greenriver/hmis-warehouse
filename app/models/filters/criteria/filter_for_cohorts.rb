class Filters::Criteria::FilterForCohorts< Filters::Criteria::Base
  LEVEL = :client

  def applies? = input.ce_cls_as_homeless

  def apply(scope)
    client_ids_with_two_homeless_cls = scope.ce.joins(enrollment: :current_living_situations).
      merge(GrdaWarehouse::Hud::CurrentLivingSituation.homeless.between(start_date: input.start_date, end_date: input.end_date)).group(arel.she_t[:client_id]).
      having(nf('COUNT', [arel.she_t[:client_id]]).gt(1)).
      select(:client_id)
    p_types = config.project_types.presence || input.project_type_ids
    scope.where(client_id: client_ids_with_two_homeless_cls).
      or(scope.where(project_type: p_types))
  end

end
