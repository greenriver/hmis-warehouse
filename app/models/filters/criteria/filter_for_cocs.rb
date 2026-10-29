###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForCocs < Filters::Criteria::Base
  class UnlimitedProjectCocJoin < StandardError; end

  # Attached to every scope this filter returns, even when no CoC is chosen, so specs that pick no
  # CoC still hit it.
  #
  # The filter keeps enrollments whose project has a ProjectCoC in the selected CoCs, using EXISTS
  # so each enrollment comes back once. It does not join ProjectCoC. A later
  # `joins(project: :project_cocs)` is a new, unrestricted join: it returns every CoC the project is
  # in, and repeats the enrollment once per ProjectCoC row. The filter can't restrict that join
  # without making it itself, which brings back the repeated rows.
  #
  # Reports that need ProjectCoC columns (CoCCode, Zip, ...) call
  # `ServiceHistoryEnrollment.joins_project_cocs(coc_codes: filter.coc_codes)`, which joins with
  # Arel and limits the rows to the selected CoCs.
  #
  # Checks association-style joins (`joins`, `left_outer_joins`, a same-model `merge`) whether they
  # were added before or after the filter. Joins written in Arel or SQL, and ones merged in from
  # another model's relation, aren't checked.
  module ProjectCocJoinGuard
    def self.extended(relation)
      relation.send(:check_project_coc_joins!, relation.joins_values + relation.left_outer_joins_values)
    end

    def joins_values=(value)
      check_project_coc_joins!(value)
      super
    end

    def left_outer_joins_values=(value)
      check_project_coc_joins!(value)
      super
    end

    private def check_project_coc_joins!(joins)
      return unless joins.any? { |join| project_coc_join?(join) }

      raise UnlimitedProjectCocJoin,
            'Joining project: :project_cocs after filter_for_cocs returns every CoC the project is in. ' \
            'Use joins_project_cocs(coc_codes:) instead; see Filters::Criteria::FilterForCocs::ProjectCocJoinGuard.'
    end

    private def project_coc_join?(join)
      case join
      when Hash
        join.any? { |key, value| (key.to_s == 'project' && names_project_cocs?(value)) || project_coc_join?(value) }
      when Array
        join.any? { |value| project_coc_join?(value) }
      else
        false
      end
    end

    private def names_project_cocs?(value)
      case value
      when Symbol, String then value.to_s == 'project_cocs'
      when Hash then value.keys.any? { |key| names_project_cocs?(key) }
      when Array then value.any? { |v| names_project_cocs?(v) }
      else false
      end
    end
  end

  def applies? = true

  def apply(scope)
    scope = super(scope).extending(ProjectCocJoinGuard)
    return scope unless input.coc_codes.present?

    scope = filter_for_project_cocs(scope)
    filter_for_enrollment_cocs(scope)
  end

  protected

  # EXISTS rather than a join: projects can have several ProjectCoC rows in the same CoC, and
  # joining them repeats each enrollment once per row. Not a `where(id:)` on Project either,
  # because merging a later `where(id:)` (user access, project filters) would replace it.
  def filter_for_project_cocs(scope)
    p_t = GrdaWarehouse::Hud::Project.arel_table
    pc_t = GrdaWarehouse::Hud::ProjectCoc.arel_table
    matching_project_cocs = GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: input.coc_codes).
      where(pc_t[:data_source_id].eq(p_t[:data_source_id]).and(pc_t[:ProjectID].eq(p_t[:ProjectID])))
    scope.joins(:project).where(matching_project_cocs.arel.exists)
  end

  def filter_for_enrollment_cocs(scope)
    scope.left_outer_joins(:enrollment).
      # limit enrollment coc to the cocs chosen, and any random thing that's not a valid coc
      merge(
        GrdaWarehouse::Hud::Enrollment.where(EnrollmentCoC: input.coc_codes).
        or(GrdaWarehouse::Hud::Enrollment.where(EnrollmentCoC: nil)).
        or(GrdaWarehouse::Hud::Enrollment.where.not(EnrollmentCoC: HudHelper.util.cocs.keys)),
      )
  end
end
