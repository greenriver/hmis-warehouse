class RecreateViewsWithIncorrectPrimaryKeys < ActiveRecord::Migration
  def up
    # drop and create thing in the correct order
    drop_order
    create_order
  end

  def down
  end

  def client_model
    GrdaWarehouse::Hud::Client
  end

  def source_client_table
    @source_client_table ||= Arel::Table.new(
      GrdaWarehouse::Hud::Client.table_name
    ).tap{ |t| t.table_alias = 'source_clients' }
  end

  def destination_client_table
    @destination_client_table ||= Arel::Table.new(
      GrdaWarehouse::Hud::Client.table_name
    ).tap{ |t| t.table_alias = 'destination_clients' }
  end

  def enrollments_table
    GrdaWarehouse::Hud::Enrollment.arel_table
  end

  def join_to_enrollments(table)
    at = if table.respond_to?(:engine)
      table.engine.arel_table
    else
      table
    end
    model = GrdaWarehouse::Hud::Enrollment.arel_table
    table.join(model).on(
      at[:data_source_id].eq(model[:data_source_id]).
      and( at[:PersonalID].eq model[:PersonalID] ).
      and( at[:ProjectEntryID].eq model[:ProjectEntryID] ).
      and( model[:DateDeleted].eq nil )
    )
  end

  def client_join_table
    GrdaWarehouse::WarehouseClient.arel_table
  end

  def join_source_and_client(table)
    at = if table.respond_to?(:engine)
      table.engine.arel_table
    else
      table
    end
    table.join(source_client_table).on(
      at[:data_source_id].eq(source_client_table[:data_source_id]).
      and( at[:PersonalID].eq source_client_table[:PersonalID] ).
      and( source_client_table[:DateDeleted].eq nil )
    ).join(client_join_table).on(
      source_client_table[:id].eq client_join_table[:source_id]
    ).join(destination_client_table).on(
      destination_client_table[:id].eq(client_join_table[:destination_id]).
      and( destination_client_table[:DateDeleted].eq nil )
    )
  end

  # see 20161111210852
  def enrollments_up!
    query = join_source_and_client(enrollments_table).
      project(
        *enrollments_table.engine.column_names.map(&:to_sym).map{ |c| enrollments_table[c] },  # all the enrollment columns
        source_client_table[:id].as('demographic_id'),                                         # the source client id
        destination_client_table[:id].as('client_id')                                          # the destination client id
      ).where(
        enrollments_table[:DateDeleted].eq nil
      )

    create_view :report_enrollments, query
  end

  # see 20161115194005
  def employment_education_up!
    model = GrdaWarehouse::Hud::EmploymentEducation
    gh_em_ed_table = join_source_and_client(model.arel_table)
    gh_em_ed_table = join_to_enrollments gh_em_ed_table
    query = gh_em_ed_table.project(
      *gh_em_ed_table.engine.column_names.map(&:to_sym).map{ |c| model.arel_table[c] },  # all employment education columns
      enrollments_table[:id].as('enrollment_id'),                                        # a fake enrollment foreign key
      source_client_table[:id].as('demographic_id'),                                     # a fake source client foreign key
      destination_client_table[:id].as('client_id')                                      # a fake destination client foreign key
    )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_employment_educations, query
  end

  # see 20161115173437
  def disabilities_up!
    model = GrdaWarehouse::Hud::Disability
    gh_disability_table = join_source_and_client model.arel_table
    gh_disability_table = join_to_enrollments gh_disability_table
    query = gh_disability_table.project(
      *gh_disability_table.engine.column_names.map(&:to_sym).map{ |c| model.arel_table[c] },  # all disability columns
      enrollments_table[:id].as('enrollment_id'),                                             # a fake foreign key to the enrollments table
      source_client_table[:id].as('demographic_id'),                                          # a fake foreign key to the source client
      destination_client_table[:id].as('client_id')                                           # a fake fore
    )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_disabilities, query
  end

  # see 20161115160857
  def exits_up!
    model = GrdaWarehouse::Hud::Exit
    gh_exit_table = join_source_and_client model.arel_table
    gh_exit_table = join_to_enrollments gh_exit_table
    query = gh_exit_table.project(
      *gh_exit_table.engine.column_names.map(&:to_sym).map{ |c| model.arel_table[c] },  # all the exit columns
      enrollments_table[:id].as('enrollment_id'),                                       # a fake enrollment foreign key
      source_client_table[:id].as('demographic_id'),                                    # a fake foreign key to the source client
      destination_client_table[:id].as('client_id')                                     # a fake destination client foreign key
    )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_exits, query
  end

  # 20161115163024
  def health_and_dvs_up!
    model = GrdaWarehouse::Hud::HealthAndDv
    gh_health_and_dv_table = join_source_and_client model.arel_table
    gh_health_and_dv_table = join_to_enrollments gh_health_and_dv_table
    query = gh_health_and_dv_table.project(
      *gh_health_and_dv_table.engine.column_names.map(&:to_sym).map{ |c| model.arel_table[c] },
      enrollments_table[:id].as('enrollment_id'),
      source_client_table[:id].as('demographic_id'),
      destination_client_table[:id].as('client_id')
    )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_health_and_dvs, query
  end

  # 20161115181519
  def income_benefits_up!
    model = GrdaWarehouse::Hud::IncomeBenefit
    gh_income_benefit_table = join_source_and_client model.arel_table
    gh_income_benefit_table = join_to_enrollments gh_income_benefit_table
    query = gh_income_benefit_table.project(
      *gh_income_benefit_table.engine.column_names.map(&:to_sym).map{ |c| model.arel_table[c] },
      enrollments_table[:id].as('enrollment_id'),
      source_client_table[:id].as('demographic_id'),
      destination_client_table[:id].as('client_id')
    )

    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end

    create_view :report_income_benefits, query
  end

  # 20161111214343
  def services_up!
    model = GrdaWarehouse::Hud::Service
    gh_service_table = join_source_and_client model.arel_table
    gh_service_table = join_to_enrollments gh_service_table
    query = gh_service_table.project(
      *gh_service_table.engine.column_names.map(&:to_sym).map{ |c| model.arel_table[c] },
      enrollments_table[:id].as('enrollment_id'),
      source_client_table[:id].as('demographic_id'),
      destination_client_table[:id].as('client_id')
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
    drop_view :report_enrollments
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
