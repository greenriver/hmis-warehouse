require 'test_helper'
require 'support/import_factory'
# run with: 
# bin/rake test TEST="test/data_integration/import_test.rb"

class ImportTest < ActiveSupport::TestCase
  
  def setup
    create_data_sources
  end

  def teardown
    destroy_import_logs
    destroy_warehouse_data
    destroy_data_sources
  end

  def test_initial_import
    Importers::Samba.new().run!
    client = GrdaWarehouse::Hud::Client.where('PersonalID' => 'GRDA111115B559A4F7aCBE3asd3').first
    unchanged = GrdaWarehouse::Hud::Exit.where('ExitID' => [1,2,3]).to_a

    assert_equal 4, GrdaWarehouse::Hud::Client.count
    assert_equal 12, GrdaWarehouse::Hud::Enrollment.count
    assert_equal 9, GrdaWarehouse::Hud::Exit.count
    assert_equal 11, GrdaWarehouse::Hud::Service.count
  
    assert_equal 6, client.services.count

    @ds.file_path = 'var/test/hmis/grda_2'
    @ds.save
    Importers::Samba.new().run!
    assert_equal 7, GrdaWarehouse::Hud::Client.count
    assert_equal 17, GrdaWarehouse::Hud::Enrollment.count
    assert_equal 17, GrdaWarehouse::Hud::Exit.count
    assert_equal 13, GrdaWarehouse::Hud::Service.count

    # # Check updated records are correctly updated
    # GrdaWarehouse::Hud::Exit.where('ExitID' => [4,5,6]).each do |e|
    #   assert_equal '2014-09-01'.to_date, e.ExitDate
    # end
    # # Check non-updated records haven't changed
    # assert_equal unchanged, GrdaWarehouse::Hud::Exit.where('ExitID' => [1,2,3]).to_a

    # assert_equal 9, client.services.count
  end

   
  private def create_data_sources
    @ds = GrdaWarehouse::DataSource.where(name: 'Test Data Source').first_or_create do |m|
      m.file_path = 'var/test/hmis/grda_1'
      m.source_type = 'samba'
    end
  end
  
  private def destroy_import_logs
    GrdaWarehouse::ImportLog.destroy_all
  end

  private def destroy_data_sources
    @ds.destroy!
  end

  private def destroy_warehouse_data
    GrdaWarehouse::ServiceHistory.delete_all
    GrdaWarehouse::WarehouseClientsProcessed.delete_all
    GrdaWarehouse::WarehouseClient.delete_all
    GrdaWarehouse::Hud::Affiliation.delete_all
    GrdaWarehouse::Hud::Disability.delete_all
    GrdaWarehouse::Hud::EmploymentEducation.delete_all
    GrdaWarehouse::Hud::Enrollment.delete_all
    GrdaWarehouse::Hud::EnrollmentCoc.delete_all
    GrdaWarehouse::Hud::Exit.delete_all
    GrdaWarehouse::Hud::Funder.delete_all
    GrdaWarehouse::Hud::HealthAndDv.delete_all
    GrdaWarehouse::Hud::IncomeBenefit.delete_all
    GrdaWarehouse::Hud::Service.delete_all
    GrdaWarehouse::Hud::Inventory.delete_all
    GrdaWarehouse::Hud::Organization.delete_all
    GrdaWarehouse::Hud::Project.delete_all
    GrdaWarehouse::Hud::ProjectCoc.delete_all
    GrdaWarehouse::Hud::Site.delete_all
    GrdaWarehouse::Hud::Export.delete_all
    GrdaWarehouse::Hud::Client.delete_all
    GrdaWarehouse::Hud::Affiliation.with_deleted.delete_all
    GrdaWarehouse::Hud::Disability.with_deleted.delete_all
    GrdaWarehouse::Hud::EmploymentEducation.with_deleted.delete_all
    GrdaWarehouse::Hud::Enrollment.with_deleted.delete_all
    GrdaWarehouse::Hud::EnrollmentCoc.with_deleted.delete_all
    GrdaWarehouse::Hud::Exit.with_deleted.delete_all
    GrdaWarehouse::Hud::Funder.with_deleted.delete_all
    GrdaWarehouse::Hud::HealthAndDv.with_deleted.delete_all
    GrdaWarehouse::Hud::IncomeBenefit.with_deleted.delete_all
    GrdaWarehouse::Hud::Service.with_deleted.delete_all
    GrdaWarehouse::Hud::Inventory.with_deleted.delete_all
    GrdaWarehouse::Hud::Organization.with_deleted.delete_all
    GrdaWarehouse::Hud::Project.with_deleted.delete_all
    GrdaWarehouse::Hud::ProjectCoc.with_deleted.delete_all
    GrdaWarehouse::Hud::Client.with_deleted.delete_all
  end

end

