###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Vispdats::Synthetic
  class Base < ::GrdaWarehouse::Synthetic::Assessment
    include ArelHelper

    validates_presence_of :source

    def assessment_date
      source.submitted_at.to_date
    end

    def assessment_location
      source.user&.agency&.name || 'Unknown'
    end

    def assessment_type
      case source.contact_method
      when 'contact_phone'
        1
      when 'contact_virtual'
        2
      when 'contact_in_person'
        3
      else
        2 # default to virtual
      end
    end

    def assessment_level
      2 # Housing Needs Assessment
    end

    def prioritization_status
      return 1 if source.score >= 4 # Placed on prioritization list

      2 # Not placed on prioritization list
    end

    def data_source
      'VI-SPDAT'
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
      new_vispdats = GrdaWarehouse::Vispdat::Base.
        joins(:client).
        completed.
        where.not(id: self.select(:source_id))
      new_vispdats.find_each do |vispdat|
        create(enrollment: find_enrollment(vispdat), client: vispdat.client, source: vispdat)
      end
    end

    def self.find_enrollment(vispdat)
      # The open enrollment started closest to the date the VI-SPDAT was submitted
      enrollment_candidates = vispdat.client.service_history_entries.
        ongoing(on_date: vispdat.submitted_at.to_date).
        where(she_t[:first_date_in_program].lteq(vispdat.submitted_at.to_date)).
        order(she_t[:first_date_in_program].desc)

      enrollment_candidates.first&.enrollment
    end
  end
end
