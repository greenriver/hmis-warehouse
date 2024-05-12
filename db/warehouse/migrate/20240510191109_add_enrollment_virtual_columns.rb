class AddEnrollmentVirtualColumns < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
         do_migrate
    end
  end
  def down
    safety_assured do
      do_rollback
    end
  end

  def tables
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
        ]
  end

  def do_migrate
    create_update_enrollment_slug_fn
    create_update_enrollment_fields_fn
    tables.each do |table_name|
      add_column table_name, :enrollment_slug, :string
      #populate_column(table_name)
      #change_column_null table_name, :enrollment_slug, false
      add_update_enrollment_slug_trigger(table_name)
      add_update_enrollment_fields_trigger(table_name)
    end
  end

  def populate_column(table_name)
    execute %(UPDATE "#{table_name}" SET enrollment_slug = "EnrollmentID" || ':' || "PersonalID" || ':' || data_source_id)
  end

  def do_rollback
    create_update_enrollment_slug_fn
    create_update_enrollment_fields_fn
    tables.each do |table_name|
      execute(%(DROP TRIGGER trg_#{table_name.underscore}_update_enrollment_slug ON "#{table_name}"))
      execute(%(DROP TRIGGER trg_#{table_name.underscore}_update_enrollment_fields ON "#{table_name}"))
      remove_column table_name, :enrollment_slug, :string
    end
    execute('DROP FUNCTION update_enrollment_fields')
    execute('DROP FUNCTION update_enrollment_slug')
  end

  def create_update_enrollment_fields_fn
    execute <<~SQL
    CREATE OR REPLACE FUNCTION update_enrollment_fields()
    RETURNS TRIGGER AS $$
    DECLARE
        new_enrollment_id TEXT;
        new_personal_id TEXT;
        new_data_source_id TEXT;
        casted_data_source_id BIGINT;
    BEGIN
        -- Split the enrollment_slug into parts
        new_enrollment_id := split_part(NEW.enrollment_slug, ':', 1);
        new_personal_id := split_part(NEW.enrollment_slug, ':', 2);
        new_data_source_id := split_part(NEW.enrollment_slug, ':', 3);
        casted_data_source_id := new_data_source_id::BIGINT;

        -- Only update if the values actually need to change
        IF NEW."EnrollmentID" IS DISTINCT FROM new_enrollment_id THEN
            NEW."EnrollmentID" := new_enrollment_id;
        END IF;
        IF NEW."PersonalID" IS DISTINCT FROM new_personal_id THEN
            NEW."PersonalID" := new_personal_id;
        END IF;
        IF NEW.data_source_id IS DISTINCT FROM casted_data_source_id THEN
            NEW.data_source_id := casted_data_source_id;
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
    BEFORE INSERT OR UPDATE ON "#{table_name}"
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
    BEFORE INSERT OR UPDATE ON "#{table_name}"
    FOR EACH ROW
    WHEN (OLD.enrollment_slug IS DISTINCT FROM NEW.enrollment_slug)
    EXECUTE FUNCTION update_enrollment_fields();
    SQL
  end
end
