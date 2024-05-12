class AddEnrollmentVirtualColumns < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      create_update_enrollment_slug_fn
      create_update_enrollment_fields_fn
      [
        'Enrollment',
        'Disabilities',
        'EmploymentEducation',
        'Exit',
        'HealthAndDV',
        'IncomeBenefits',
        'Services',
        'CurrentLivingSituation',
        'CustomAssessments',
        'CustomServices',
        'Assessment',
        'AssessmentQuestions',
        'AssessmentResults',
        'Event',
        'YouthEducationStatus',
      ].each do |table_name|
        add_column table_name, :enrollment_slug, :string
        add_update_enrollment_slug_trigger(table_name)
        add_update_enrollment_fields_trigger(table_name)
      end
    end
  end

  def create_update_enrollment_fields_fn
    execute <<~SQL
    CREATE OR REPLACE FUNCTION update_enrollment_fields()
    RETURNS TRIGGER AS $$
    DECLARE
        new_enrollment_id TEXT;
        new_personal_id TEXT;
        new_data_source_id TEXT;
    BEGIN
        -- Split the enrollment_slug into parts
        new_enrollment_id := split_part(NEW.enrollment_slug, ':', 1);
        new_personal_id := split_part(NEW.enrollment_slug, ':', 2);
        new_data_source_id := split_part(NEW.enrollment_slug, ':', 3);

        -- Only update if the values actually need to change
        IF NEW."EnrollmentID" IS DISTINCT FROM new_enrollment_id THEN
            NEW."EnrollmentID" := new_enrollment_id;
        END IF;
        IF NEW."PersonalID" IS DISTINCT FROM new_personal_id THEN
            NEW."PersonalID" := new_personal_id;
        END IF;
        IF NEW.data_source_id IS DISTINCT FROM new_data_source_id THEN
            NEW.data_source_id := new_data_source_id;
        END IF;

        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    SQL
  end

  def create_update_enrollment_slug_fn
    execute <<~SQL
    CREATE OR REPLACE FUNCTION update_enrollment_slug()
    RETURNS TRIGGER AS $$
    BEGIN
        -- Generate new slug from current field values
        IF NEW.enrollment_slug IS DISTINCT FROM (NEW."EnrollmentID" || ':' || NEW."PersonalID" || ':' || NEW.data_source_id) THEN
            NEW.enrollment_slug := NEW."EnrollmentID" || ':' || NEW."PersonalID" || ':' || NEW.data_source_id;
        END IF;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    SQL
  end

  def add_update_enrollment_slug_trigger(table_name)
    execute <<~SQL
    CREATE TRIGGER trg_#{table_name.underscore}_update_enrollment_slug
    BEFORE UPDATE ON "#{table_name}"
    FOR EACH ROW
    WHEN (OLD."EnrollmentID" IS DISTINCT FROM NEW."EnrollmentID" OR
          OLD."PersonalID" IS DISTINCT FROM NEW."PersonalID" OR
          OLD.data_source_id IS DISTINCT FROM NEW.data_source_id)
    EXECUTE FUNCTION update_enrollment_slug();
    SQL
  end

  def add_update_enrollment_fields_trigger(table_name)
    execute <<~SQL
    CREATE TRIGGER trg_#{table_name.underscore}_update_enrollment_fields
    BEFORE UPDATE ON "#{table_name}"
    FOR EACH ROW
    WHEN (OLD.enrollment_slug IS DISTINCT FROM NEW.enrollment_slug)
    EXECUTE FUNCTION update_enrollment_fields();
    SQL
  end
end
