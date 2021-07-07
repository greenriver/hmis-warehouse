###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Vispdats::Synthetic
  class Base < ::GrdaWarehouse::Synthetic::Assessment
    validates_presence_of :source

    def assessment_date
      source.submitted_at&.to_date
    end

    def assessment_location
      source.user&.agency&.name
    end

    def assessment_type
      # FIXME
      3 # In Person
    end

    def assessment_level
      # FIXME
      1 # Crisis Needs Assessment
    end

    def priortization_status
      # FIXME
      2 # Not placed on prioritization list
    end

    def self.sync
      remove_orphans
      add_new
    end

    def self.remove_orphans
      orphan_ids = pluck(:source_id) - GrdaWarehouse::Vispdat::Base.pluck(:id)
      return unless orphan_ids.present?

      where(source_id: orphan_ids).delete_all
    end

    def self.add_new
      new_vispdats = GrdaWarehouse::Vispdat::Base.where.not(id: self.select(:source_id))
      new_vispdats.find_each do |vispdat|
        next unless vispdat.client.present? && vispdat.submitted_at.present?

        create(enrollment: find_enrollment(vispdat), client: vispdat.client, source: vispdat)
      end
    end

    def self.find_enrollment(vispdat)
      project_candidates = GrdaWarehouse::Hud::Project.pluck(:ProjectID) # FIXME
      vispdat.client.service_history_entries.
        where(project_id: project_candidates).
        ongoing(on_date: vispdat.submitted_at.to_date)&.
        first&.
        enrollment
    end
  end
end
