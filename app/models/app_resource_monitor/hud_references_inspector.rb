###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# report on invalid HUD references
class AppResourceMonitor::HudReferencesInspector
  def self.enrollment_references
    new.enrollment_references
  end

  def self.project_references
    new.project_references
  end

  def self.client_references
    new.client_references
  end

  def self.duplicate_ids
    new.duplicate_ids
  end

  def hud_models
    Rails.application.eager_load!
    seen = Set.new
    results = []
    [
      GrdaWarehouse::Hud::Base,
      Hmis::Hud::Base,
    ].each do |base_class|
      base_class.descendants.each do |klass|
        table_name = klass.table_name
        next unless table_name
        next if table_name.in?(seen)
        next unless klass.try(:hud_key)
        next unless klass.reflect_on_association(:data_source)

        seen.add(table_name)
        results << klass
      end
    end
    results
  end

  def duplicate_ids
    hud_models.flat_map do |model|
      arel_table = model.arel_table
      hud_key = arel_table[model.hud_key]
      data_sources.map do |data_source|
        scope = model.where(data_source: data_source)
        {
          data_source_id: data_source.id,
          table_name: model.table_name,
          duplicates: scope.where(data_source: data_source).select(hud_key).group(hud_key).having('count(*) > 1').count.values.sum,
        }
      end
    end
  end

  def client_references
    hud_models.filter(&:references_hud_client?).flat_map do |model|
      data_sources.map do |data_source|
        scope = model.where(data_source: data_source)
        {
          data_source_id: data_source.id,
          table_name: model.table_name,
          dangling_clients: scope.left_outer_joins(:client).where(arel.c_t[:id].eq(nil)).count,
        }
      end
    end
  end

  def project_references
    hud_models.filter(&:references_hud_project?).flat_map do |model|
      data_sources.map do |data_source|
        scope = model.where(data_source: data_source)
        {
          data_source_id: data_source.id,
          table_name: model.table_name,
          dangling_projects: scope.left_outer_joins(:project).where(arel.p_t[:id].eq(nil)).count,
        }
      end
    end
  end

  def enrollment_references
    hud_models.filter(&:references_hud_enrollment?).flat_map do |model|
      arel_table = model.arel_table
      # to detect mismatched enrollment/client ids, we join using only EnrollmentID / data_source
      q_table_name = model.connection.quote_table_name(model.table_name)
      enrollment_join_sql = <<~SQL
        JOIN "Enrollment" ON "Enrollment"."DateDeleted" IS NULL
        AND "Enrollment"."EnrollmentID" = #{q_table_name}."EnrollmentID"
        AND "Enrollment"."data_source_id" = #{q_table_name}."data_source_id"
      SQL
      data_sources.map do |data_source|
        scope = model.where(data_source: data_source)
        {
          data_source_id: data_source.id,
          table_name: model.table_name,
          # EnrollmentID does not match any undeleted Enrollment
          dangling_enrollments: scope.joins("LEFT OUTER #{enrollment_join_sql}").where(arel.e_t[:id].eq(nil)).count,
          # PersonalID is different from enrollment.PersonalID ("mismatch")
          mismatched_enrollments: scope.joins(enrollment_join_sql).where(arel_table[:personal_id].not_eq(arel.e_t[:personal_id])).count,
        }
      end
    end
  end

  def arel
    Hmis::ArelHelper.instance
  end

  def data_sources
    GrdaWarehouse::DataSource.order(:id)
  end
end
