class EncryptedFields < ActiveRecord::Migration[5.2]
  def change
    [
      :encrypted_FirstName,
      :encrypted_FirstName_iv,
      :encrypted_MiddleName,
      :encrypted_MiddleName_iv,
      :encrypted_LastName,
      :encrypted_LastName_iv,
      :encrypted_SSN,
      :encrypted_SSN_iv,
      :encrypted_NameSuffix,
      :encrypted_NameSuffix_iv,
    ].each do |column_name|
      add_column :Client, column_name, :string
    end

    reversible do |r|
      r.up do
        drop_views_blocking_change_in_ssn!
        # It might be encrypted, which will be longer than 9
        change_column :Client, :SSN, :string, length: 255
        redo_views!
      end

      r.down do
        drop_views_blocking_change_in_ssn!
        change_column :Client, :SSN, :string, length: 9
        redo_views!
      end
    end
  end

  def drop_views_blocking_change_in_ssn!
    execute("DROP VIEW IF EXISTS report_demographics")
    execute("DROP VIEW IF EXISTS report_clients")
  end

  def redo_views!
    # TDB: FIXME: how are we managing views in this application?
    create_view "report_clients", sql_definition: <<-SQL
        SELECT "Client"."PersonalID",
        "Client"."FirstName",
        "Client"."MiddleName",
        "Client"."LastName",
        "Client"."NameSuffix",
        "Client"."NameDataQuality",
        "Client"."SSN",
        "Client"."SSNDataQuality",
        "Client"."DOB",
        "Client"."DOBDataQuality",
        "Client"."AmIndAKNative",
        "Client"."Asian",
        "Client"."BlackAfAmerican",
        "Client"."NativeHIOtherPacific",
        "Client"."White",
        "Client"."RaceNone",
        "Client"."Ethnicity",
        "Client"."Gender",
        "Client"."OtherGender",
        "Client"."VeteranStatus",
        "Client"."YearEnteredService",
        "Client"."YearSeparated",
        "Client"."WorldWarII",
        "Client"."KoreanWar",
        "Client"."VietnamWar",
        "Client"."DesertStorm",
        "Client"."AfghanistanOEF",
        "Client"."IraqOIF",
        "Client"."IraqOND",
        "Client"."OtherTheater",
        "Client"."MilitaryBranch",
        "Client"."DischargeStatus",
        "Client"."DateCreated",
        "Client"."DateUpdated",
        "Client"."UserID",
        "Client"."DateDeleted",
        "Client"."ExportID",
        "Client".id
       FROM "Client"
      WHERE (("Client"."DateDeleted" IS NULL) AND ("Client".data_source_id IN ( SELECT data_sources.id
               FROM data_sources
              WHERE (data_sources.source_type IS NULL))));
    SQL

    create_view "report_demographics", sql_definition: <<-SQL
        SELECT "Client"."PersonalID",
        "Client"."FirstName",
        "Client"."MiddleName",
        "Client"."LastName",
        "Client"."NameSuffix",
        "Client"."NameDataQuality",
        "Client"."SSN",
        "Client"."SSNDataQuality",
        "Client"."DOB",
        "Client"."DOBDataQuality",
        "Client"."AmIndAKNative",
        "Client"."Asian",
        "Client"."BlackAfAmerican",
        "Client"."NativeHIOtherPacific",
        "Client"."White",
        "Client"."RaceNone",
        "Client"."Ethnicity",
        "Client"."Gender",
        "Client"."OtherGender",
        "Client"."VeteranStatus",
        "Client"."YearEnteredService",
        "Client"."YearSeparated",
        "Client"."WorldWarII",
        "Client"."KoreanWar",
        "Client"."VietnamWar",
        "Client"."DesertStorm",
        "Client"."AfghanistanOEF",
        "Client"."IraqOIF",
        "Client"."IraqOND",
        "Client"."OtherTheater",
        "Client"."MilitaryBranch",
        "Client"."DischargeStatus",
        "Client"."DateCreated",
        "Client"."DateUpdated",
        "Client"."UserID",
        "Client"."DateDeleted",
        "Client"."ExportID",
        "Client".data_source_id,
        "Client".id,
        report_clients.id AS client_id
       FROM (("Client"
         JOIN warehouse_clients ON ((warehouse_clients.source_id = "Client".id)))
         JOIN report_clients ON ((warehouse_clients.destination_id = report_clients.id)))
      WHERE ("Client"."DateDeleted" IS NULL);
    SQL
  end
end
