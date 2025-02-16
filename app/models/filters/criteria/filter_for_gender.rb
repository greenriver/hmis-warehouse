class Filters::Criteria::FilterForGender < Filters::Criteria::Base
  def applies? = input.genders.present?

  def apply(scope)
    scope = scope.joins(config.join_clients_method)
    gender_scope = nil
    input.genders.each do |value|
      column = HudUtility2024.gender_id_to_field_name[value]
      next unless column

      gender_query = config.report_scope_source.
        joins(config.join_clients_method).
        where(arel.c_t[column.to_sym].eq(HudUtility2024.gender_comparison_value(value)))
      gender_scope = add_alternative(gender_scope, gender_query)
    end
    scope.merge(gender_scope)
  end
end
