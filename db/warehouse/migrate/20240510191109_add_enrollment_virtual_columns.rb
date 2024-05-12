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
    create_functions
    tables.each do |table_name|
      add_column table_name, :enrollment_slug, :string
      populate_column(table_name)
      add_triggers(table_name)
    end
  end

  def populate_column(table_name)
    execute %(UPDATE "#{table_name}" SET enrollment_slug = "EnrollmentID" || ':' || "PersonalID" || ':' || data_source_id)
  end

  def do_rollback
    tables.each do |table_name|
      execute(%(DROP TRIGGER trg_#{table_name.underscore}_e1 ON "#{table_name}"))
      execute(%(DROP TRIGGER trg_#{table_name.underscore}_e2 ON "#{table_name}"))
      execute(%(DROP TRIGGER trg_#{table_name.underscore}_e3 ON "#{table_name}"))
      execute(%(DROP TRIGGER trg_#{table_name.underscore}_e4 ON "#{table_name}"))
      remove_column table_name, :enrollment_slug, :string
    end
    execute('DROP FUNCTION generate_enrollment_slug')
    execute('DROP FUNCTION split_enrollment_slug')
  end

  def create_functions
    execute <<~SQL
    CREATE FUNCTION generate_enrollment_slug()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.enrollment_slug := NEW."EnrollmentID" || ':' || NEW."PersonalID" || ':' || NEW.data_source_id;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    SQL

    execute <<~SQL
    CREATE FUNCTION split_enrollment_slug()
    RETURNS TRIGGER AS $$
    BEGIN
      IF array_length(string_to_array(NEW.enrollment_slug, ':'), 1) = 3 THEN
        NEW."EnrollmentID" := split_part(NEW.enrollment_slug, ':', 1);
        NEW."PersonalID" := split_part(NEW.enrollment_slug, ':', 2);
        NEW.data_source_id := split_part(NEW.enrollment_slug, ':', 3)::BIGINT;
      ELSE
        RAISE EXCEPTION 'enrollment_slug has an invalid format';
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    SQL
  end

  def add_triggers(table_name)
    execute <<~SQL
      CREATE TRIGGER trg_#{table_name.underscore}_e1
      BEFORE INSERT ON "#{table_name}"
      FOR EACH ROW
      WHEN (NEW.enrollment_slug IS NOT NULL)
      EXECUTE FUNCTION split_enrollment_slug();
    SQL

    execute <<~SQL
      CREATE TRIGGER trg_#{table_name.underscore}_e2
      BEFORE UPDATE ON "#{table_name}"
      FOR EACH ROW
      WHEN (OLD.enrollment_slug IS DISTINCT FROM NEW.enrollment_slug)
      EXECUTE FUNCTION split_enrollment_slug();
    SQL

    execute <<~SQL
      CREATE TRIGGER trg_#{table_name.underscore}_e3
      BEFORE INSERT ON "#{table_name}"
      FOR EACH ROW
      WHEN (NEW."EnrollmentID" IS NOT NULL AND NEW."PersonalID" IS NOT NULL AND NEW.data_source_id IS NOT NULL)
      EXECUTE FUNCTION generate_enrollment_slug();
    SQL

    execute <<~SQL
      CREATE TRIGGER trg_#{table_name.underscore}_e4
      BEFORE UPDATE ON "#{table_name}"
      FOR EACH ROW
      WHEN (OLD."EnrollmentID" IS DISTINCT FROM NEW."EnrollmentID" OR
            OLD."PersonalID" IS DISTINCT FROM NEW."PersonalID" OR
            OLD.data_source_id IS DISTINCT FROM NEW.data_source_id)
      EXECUTE FUNCTION generate_enrollment_slug();
    SQL
  end

=begin
  def create_functionsx
    execute <<~SQL
    CREATE OR REPLACE FUNCTION update_enrollment_slug()
    RETURNS TRIGGER AS $$
    DECLARE
      new_enrollment_id TEXT;
      new_personal_id TEXT;
      new_data_source_id BIGINT;
    BEGIN
    -- Generate new slug from current field values
    IF OLD."EnrollmentID" IS DISTINCT FROM NEW."EnrollmentID" OR OLD."PersonalID" IS DISTINCT FROM NEW."PersonalID" OR OLD.data_source_id IS DISTINCT FROM NEW.data_source_id THEN
      NEW.enrollment_slug := NEW."EnrollmentID" || ':' || NEW."PersonalID" || ':' || NEW.data_source_id;

    -- Set enrollment fields from new slug
    ELSIF OLD.enrollment_slug IS DISTINCT FROM NEW.enrollment_slug AND NEW.enrollment_slug IS NOT NULL THEN
      IF NEW.enrollment_slug ~ '^[^:]+:[^:]+:[^:]+$' THEN
        new_enrollment_id := split_part(NEW.enrollment_slug, ':', 1);
        new_personal_id := split_part(NEW.enrollment_slug, ':', 2);
        new_data_source_id := split_part(NEW.enrollment_slug, ':', 3)::BIGINT;

        NEW."EnrollmentID" := new_enrollment_id;
        NEW."PersonalID" := new_personal_id;
        NEW.data_source_id := new_data_source_id;
      ELSE
        RAISE EXCEPTION 'enrollment_slug has an invalid format';
      END IF;
    END IF;
    RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    SQL

    execute <<~SQL
    CREATE OR REPLACE FUNCTION insert_enrollment_slug()
    RETURNS TRIGGER AS $$
    BEGIN
    -- Generate new slug from current field values
    IF NEW."EnrollmentID" AND NEW."PersonalID" AND NEW.data_source_id AND NEW.enrollment_slug IS NULL THEN
      NEW.enrollment_slug := NEW."EnrollmentID" || ':' || NEW."PersonalID" || ':' || NEW.data_source_id;
    ELSIF NEW.enrollment_slug IS NOT NULL THEN
      IF NEW.enrollment_slug ~ '^[^:]+:[^:]+:[^:]+$' THEN
        NEW."EnrollmentID" := split_part(NEW.enrollment_slug, ':', 1);
        NEW."PersonalID" := split_part(NEW.enrollment_slug, ':', 2);
        NEW.data_source_id := split_part(NEW.enrollment_slug, ':', 3)::BIGINT;
      ELSE
        RAISE EXCEPTION 'enrollment_slug has an invalid format';
      END IF;
    END IF;
    RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    end
    SQL
  end
=end

end
