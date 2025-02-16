class Filters::Criteria::FilterForVeteranStatus < Filters::Criteria::Base
  def applies? = input.veteran_statuses.present?

  def apply(scope)
    scope.joins(config.join_clients_method).
      where(arel.c_t[:VeteranStatus].in(input.veteran_statuses))
  end
end
