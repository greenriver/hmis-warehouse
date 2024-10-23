class CleanupTalentData < ActiveRecord::Migration[7.0]
  def up
    Talentlms::Config.all.each do |c|
      Talentlms::Course.create!({
        config: c,
        courseid: c.courseid,
        months_to_expiration: c.months_to_expiration,
        name: c.configuration_name,
        default: c.default,
      })
    end

    config = Talentlms::Config.first
    Talentlms::Login.update_all(config_id: config&.id)
    Talentlms::CompletedTraining.update_all(course_id: config&.courses&.first&.id)
  end

  def down
    Talentlms::CompletedTraining.all.each do |t|
      t.course_id_old = t.course.courseid
    end

    Talentlms::Config.all.each do |c|
      c.courseid = c.courses.first&.courseid
      c.months_to_expiration = c.courses.first&.months_to_expiration
      c.configuration_name = c.courses.first&.name
      c.default = c.courses.first&.default
      c.save!
    end
  end
end