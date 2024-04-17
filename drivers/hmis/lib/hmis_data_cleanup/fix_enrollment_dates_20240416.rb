#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class FixEnrollmentDates20240416
  # For Enrollments in any project EXCEPT special treatment project, where the Entry Date and Exit Date are the same:
  # - Add one day to the exit date
  # For Enrollments in special treatment project, where the Exit Date is before the Entry Date (or they are the same):
  # - If exit date is in 2020, change it to 2023 but same month and day.
  # For Bed Night Services (recordType:200) in special treatment project, where the DateProvided is in 2020
  # - Change DateProvided to 2023 (same month and day). The project was not open in 2020

  include ArelHelper
  attr_accessor :special_treatment_project_id
  def initialize(special_treatment_project_id:)
    self.special_treatment_project_id = special_treatment_project_id
  end

  def perform
    puts "Fixing dates. Special treatment project: #{special_treatment_project_id}"
    special_project = Hmis::Hud::Project.find_by(project_id: special_treatment_project_id)
    raise 'Special project not found' unless special_project

    normal_project_ids = Hmis::Hud::Project.hmis.
      where.not(project_id: special_treatment_project_id).
      where(project_type: HudUtility2024.residential_project_type_ids).
      pluck(:project_id)

    fix_dates_special(special_treatment_project_id)
    fix_dates(normal_project_ids)
  end

  def fix_dates_special(project_id)
    puts "Updating (special): #{project_id}"

    exits_to_update = Hmis::Hud::Exit.hmis.
      joins(:enrollment, :project).
      where(p_t[:project_id].eq(project_id)).
      where(ex_t[:exit_date].extract('year').eq(2020)).
      where(e_t[:entry_date].gteq(ex_t[:exit_date]))

    puts "Found #{exits_to_update.count} enrollments with exit date in 2020 where exit date is before entry date"

    Hmis::Hud::Exit.transaction do
      exits_to_update.each do |e|
        new_date = e.exit_date.change(year: 2023)
        puts "Updating exit #{e.id} exit date to #{new_date}"
        e.exit_date = new_date
        e.save!
      end
    end

    services_to_update = Hmis::Hud::Service.
      joins(:enrollment, :project).
      where(p_t[:project_id].eq(project_id)).
      where(record_type: 200). # Bed Nights
      where(s_t[:date_provided].extract('year').eq(2020))

    puts "Found #{services_to_update.count} bed nights with date provided in 2020"

    Hmis::Hud::Service.transaction do
      services_to_update.each do |s|
        new_date = s.date_provided.change(year: 2023)
        puts "Updating service #{s.id} date provided to #{new_date}"
        s.date_provided = new_date
        s.save!
      end
    end
  end

  def fix_dates(project_ids)
    puts "Updating (normal): #{project_ids.count} projects"

    exits_to_update = Hmis::Hud::Exit.hmis.
      joins(:enrollment).
      where(e_t[:project_id].in(project_ids)).
      where(e_t[:entry_date].eq(ex_t[:exit_date]))

    puts "Found #{exits_to_update.count} enrollments with equal entry and exit dates"

    Hmis::Hud::Exit.transaction do
      exits_to_update.each do |e|
        new_date = e.exit_date + 1.day
        puts "Updating exit #{e.id} exit date to #{new_date}"
        e.exit_date = new_date
        e.save!
      end
    end
  end
end
