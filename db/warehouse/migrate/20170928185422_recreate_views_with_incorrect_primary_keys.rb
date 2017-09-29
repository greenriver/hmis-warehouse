class RecreateViewsWithIncorrectPrimaryKeys < ActiveRecord::Migration
  def up
    # drop and create thing in the correct order
    drop_order
    create_order
  end

  def down
  end

  # see 20161111210852
  def enrollments_up!
    model = GrdaWarehouse::Hud::Enrollment
    report_demographic_table = Arel::Table.new :report_demographics
    gh_enrollment_table      = model.arel_table
    query = gh_enrollment_table.
      project(
        *gh_enrollment_table.engine.column_names.map(&:to_sym).map{ |c| gh_enrollment_table[c] },  # all the enrollment columns
        report_demographic_table[:id].as('demographic_id'),                                        # the source client id
        report_demographic_table[:client_id]                                                       # the destination client id
      ).
      join(report_demographic_table).on(
        report_demographic_table[:data_source_id].eq( gh_enrollment_table[:data_source_id]).       # use the usual keys joining enrollments to clients
        and( report_demographic_table[:PersonalID].eq gh_enrollment_table[:PersonalID] )
      )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_enrollments, query
  end

  # see 20161115194005
  def employment_education_up!
    model = GrdaWarehouse::Hud::EmploymentEducation
    report_enrollment_table  = Arel::Table.new :report_enrollments
    gh_em_ed_table           = model.arel_table 
    query = gh_em_ed_table.project(
      *gh_em_ed_table.engine.column_names.map(&:to_sym).map{ |c| gh_em_ed_table[c] },  # all employment education columns
      report_enrollment_table[:id].as('enrollment_id'),                                # a fake enrollment foreign key
      report_enrollment_table[:demographic_id],                                        # a fake source client foreign key
      report_enrollment_table[:client_id]                                              # a fake destination client foreign key
    ).
      join(report_enrollment_table).on(
        report_enrollment_table[:data_source_id].eq(gh_em_ed_table[:data_source_id]).  # usual keys to join ee to enrollments
        and( report_enrollment_table[:PersonalID].eq gh_em_ed_table[:PersonalID] ).
        and( report_enrollment_table[:ProjectEntryID].eq gh_em_ed_table[:ProjectEntryID] )
      )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_employment_educations, query
  end

  # see 20161115173437
  def disabilities_up!
    model = GrdaWarehouse::Hud::Disability
    report_enrollment_table  = Arel::Table.new :report_enrollments
    gh_disability_table      = model.arel_table 
    query = gh_disability_table.project(
      *gh_disability_table.engine.column_names.map(&:to_sym).map{ |c| gh_disability_table[c] },  # all disability columns
      report_enrollment_table[:id].as('enrollment_id'),                                          # a fake foreign key to the enrollments table
      report_enrollment_table[:demographic_id],                                                  # a fake foreign key to the source client
      report_enrollment_table[:client_id]                                                        # a fake fore
    ).
      join(report_enrollment_table).on(
        report_enrollment_table[:data_source_id].eq(gh_disability_table[:data_source_id]).       # use the usual keys to join enrollments to disabilities
        and( report_enrollment_table[:ProjectEntryID].eq gh_disability_table[:ProjectEntryID] ).
        and( report_enrollment_table[:PersonalID].eq gh_disability_table[:PersonalID] )
      )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_disabilities, query
  end

  # see 20161115160857
  def exits_up!
    model = GrdaWarehouse::Hud::Exit
    report_enrollment_table = Arel::Table.new :report_enrollments
    gh_exit_table           = model.arel_table
    query = gh_exit_table.project(
      *gh_exit_table.engine.column_names.map(&:to_sym).map{ |c| gh_exit_table[c] },  # all the exit columns
      report_enrollment_table[:id].as('enrollment_id'),                              # a fake enrollment foreign key
      report_enrollment_table[:demographic_id],                                      # a fake foreign key to the source client
      report_enrollment_table[:client_id]                                            # a fake destination client foreign key
    ).
      join(report_enrollment_table).on(
        report_enrollment_table[:data_source_id].eq(gh_exit_table[:data_source_id]).
        and( report_enrollment_table[:PersonalID].eq gh_exit_table[:PersonalID] ).
        and( report_enrollment_table[:ProjectEntryID].eq gh_exit_table[:ProjectEntryID] )
      )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_exits, query
  end

  # 20161115163024
  def health_and_dvs_up!
    model = GrdaWarehouse::Hud::HealthAndDv
    report_enrollment_table = Arel::Table.new :report_enrollments
    gh_health_and_dv_table  = model.arel_table 
    query = gh_health_and_dv_table.project(
      *gh_health_and_dv_table.engine.column_names.map(&:to_sym).map{ |c| gh_health_and_dv_table[c] },
      report_enrollment_table[:id].as('enrollment_id'),
      report_enrollment_table[:demographic_id],
      report_enrollment_table[:client_id]
    ).
      join(report_enrollment_table).on(
        report_enrollment_table[:data_source_id].eq(gh_health_and_dv_table[:data_source_id]).
        and( report_enrollment_table[:PersonalID].eq gh_health_and_dv_table[:PersonalID] ).
        and( report_enrollment_table[:ProjectEntryID].eq gh_health_and_dv_table[:ProjectEntryID] )
      )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_health_and_dvs, query
  end

  # 20161115181519
  def income_benefits_up!
    model = GrdaWarehouse::Hud::IncomeBenefit
    report_enrollment_table = Arel::Table.new :report_enrollments
    gh_income_benefit_table = model.arel_table 
    query = gh_income_benefit_table.project(
      *gh_income_benefit_table.engine.column_names.map(&:to_sym).map{ |c| gh_income_benefit_table[c] },
      report_enrollment_table[:id].as('enrollment_id'),
      report_enrollment_table[:demographic_id],
      report_enrollment_table[:client_id]
    ).
      join(report_enrollment_table).on(
        report_enrollment_table[:data_source_id].eq(gh_income_benefit_table[:data_source_id]).
        and( report_enrollment_table[:PersonalID].eq gh_income_benefit_table[:PersonalID] ).
        and( report_enrollment_table[:ProjectEntryID].eq gh_income_benefit_table[:ProjectEntryID] )
      )

    if model.paranoid?
      query = query.where( gh_income_benefit_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_income_benefits, query
  end

  # 20161111214343
  def services_up!
    model = GrdaWarehouse::Hud::Service
    report_enrollment_table = Arel::Table.new :report_enrollments
    gh_service_table        = model.arel_table
    query = gh_service_table.project(
      *gh_service_table.engine.column_names.map(&:to_sym).map{ |c| gh_service_table[c] },
      report_enrollment_table[:id].as('service_id'),
      report_enrollment_table[:demographic_id],
      report_enrollment_table[:client_id]
    ).
      join(report_enrollment_table).on(
        report_enrollment_table[:data_source_id].eq(gh_service_table[:data_source_id]).
        and( report_enrollment_table[:PersonalID].eq gh_service_table[:PersonalID] ).
        and( report_enrollment_table[:ProjectEntryID].eq gh_service_table[:ProjectEntryID] )
      )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_services, query
  end

  def drop_order
    drop_view :report_services
    drop_view :report_income_benefits
    drop_view :report_health_and_dvs
    drop_view :report_exits
    drop_view :report_employment_educations
    drop_view :report_disabilities
    connection.execute "DROP VIEW report_enrollments CASCADE"
  end

  def create_order
    enrollments_up!
    disabilities_up!
    employment_education_up!
    exits_up!
    health_and_dvs_up!
    income_benefits_up!
    services_up!
  end

end
