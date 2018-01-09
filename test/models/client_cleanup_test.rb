require 'test_helper'

class ClientCleanupTest < ActiveSupport::TestCase

  DEFAULT_DEST_ATTR = {
      FirstName: 'Blair', 
      LastName: 'Abbott', 
      SSN: '555-55-5555', 
      DOB: '06-12-1978', 
      VeteranStatus: nil,
      Gender: nil
    }

  def test_update_name_from_sources
    dest_attr = DEFAULT_DEST_ATTR.dup
    client_sources = [
      {FirstName: 'Correct', LastName: 'Update', NameDataQuality: 99},
      {FirstName: '', LastName: '', NameDataQuality: 9}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert dest_attr[:FirstName] == 'Correct' && dest_attr[:LastName] == 'Update', 'blank names are not selected'

    dest_attr = DEFAULT_DEST_ATTR.dup
    client_sources = [
      {FirstName: '', LastName: '', NameDataQuality: 99},
      {FirstName: '', LastName: '', NameDataQuality: 9}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal 'Blair', dest_attr[:FirstName], 'keep original first name field if all sources are blank'
    assert_equal 'Abbott', dest_attr[:LastName], 'keep original last name field if all sources are blank'

    dest_attr = DEFAULT_DEST_ATTR.dup
    client_sources = [
      {FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: 99},
      {FirstName: 'Right', LastName: 'Right', NameDataQuality: 9}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal 'Right', dest_attr[:FirstName], 'highest quality record first name wins'
    assert_equal 'Right', dest_attr[:LastName], 'highest quality record last name wins'

    dest_attr = DEFAULT_DEST_ATTR.dup
    client_sources = [
      {FirstName: 'Wrong', LastName: 'Wrong', NameDataQuality: 9, DateCreated: Date.new(2017,5,1)},
      {FirstName: 'Right', LastName: 'Right', NameDataQuality: 9, DateCreated: Date.new(2016,5,1)}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal 'Right', dest_attr[:FirstName], 'oldest record first name wins for equivalent quality'
    assert_equal 'Right', dest_attr[:LastName], 'oldest record last name wins for equivalent quality'
  end

  def test_update_dob_from_sources
    dest_attr = DEFAULT_DEST_ATTR.dup
    mark = Date.new(1978, 6, 12)
    beth = Date.new(1977, 10, 31)
    client_sources = [
      {DOB: nil, DOBDataQuality: 99},
      {DOB: nil, DOBDataQuality: 9}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert dest_attr[:DOB].nil?, 'DOB set to nil if all client records are blank'

    dest_attr = DEFAULT_DEST_ATTR.dup
    client_sources = [
      {DOB: mark, DOBDataQuality: 99},
      {DOB: nil, DOBDataQuality: 9}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal mark, dest_attr[:DOB], 'only update from clients with a value'

    dest_attr = DEFAULT_DEST_ATTR.dup
    client_sources = [
      {DOB: mark, DOBDataQuality: 99},
      {DOB: beth, DOBDataQuality: 9}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal beth, dest_attr[:DOB], 'highest quality DOB wins'

    dest_attr = DEFAULT_DEST_ATTR.dup
    client_sources = [
      {DOB: mark, DOBDataQuality: 9, DateCreated: Date.new(2016,5,1)},
      {DOB: beth, DOBDataQuality: 9, DateCreated: Date.new(2017,5,1)}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal mark, dest_attr[:DOB], 'oldest record first name wins for equivalent quality'
  end

  def test_ssn_from_sources
    dest_attr = DEFAULT_DEST_ATTR.dup
    mark = '123-45-6789'
    beth = '987-65-4321'
    client_sources = [
      {SSN: nil, SSNDataQuality: 99},
      {SSN: nil, SSNDataQuality: 9}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert dest_attr[:SSN].nil?, 'SSN set to nil if all client records are blank'

    dest_attr = DEFAULT_DEST_ATTR.dup
    client_sources = [
      {SSN: mark, SSNDataQuality: 99},
      {SSN: nil, SSNDataQuality: 9}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal mark, dest_attr[:SSN], 'only update from clients with a value'

    dest_attr = DEFAULT_DEST_ATTR.dup
    client_sources = [
      {SSN: mark, SSNDataQuality: 99},
      {SSN: beth, SSNDataQuality: 9}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal beth, dest_attr[:SSN], 'highest quality SSN wins'

    dest_attr = DEFAULT_DEST_ATTR.dup
    client_sources = [
      {SSN: mark, SSNDataQuality: 9, DateCreated: Date.new(2017,5,1)},
      {SSN: beth, SSNDataQuality: 9, DateCreated: Date.new(2016,5,1)}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal beth, dest_attr[:SSN], 'oldest record first name wins for equivalent quality'
  end

  def test_veteran_status_from_sources
    dest_attr = DEFAULT_DEST_ATTR.dup
    veteran = '1'
    civilian = '0'
    client_sources = [
      {VeteranStatus: nil, DateUpdated: 3.days.ago},
      {VeteranStatus: '99', DateUpdated: 2.days.ago}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal '99', dest_attr[:VeteranStatus], 'VeteranStatus nil overwritten if something is non-blank'

    dest_attr = DEFAULT_DEST_ATTR.dup
    dest_attr[:VeteranStatus] = veteran
    client_sources = [
      {VeteranStatus: '99', DateUpdated: 3.days.ago},
      {VeteranStatus: '8', DateUpdated: 2.days.ago}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal veteran, dest_attr[:VeteranStatus], 'only update veteran status yes/no if some client is yes/no'

    dest_attr = DEFAULT_DEST_ATTR.dup
    dest_attr[:VeteranStatus] = veteran
    client_sources = [
      {VeteranStatus: civilian, DateUpdated: 1.day.ago},
      {VeteranStatus: veteran, DateUpdated: 2.days.ago}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal civilian, dest_attr[:VeteranStatus], 'newest yes/no overwrites'

    dest_attr = DEFAULT_DEST_ATTR.dup
    dest_attr[:VeteranStatus] = veteran
    client_sources = [
      {VeteranStatus: civilian, DateUpdated: 2.days.ago},
      {VeteranStatus: veteran, DateUpdated: 1.days.ago}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal veteran, dest_attr[:VeteranStatus], 'newest yes/no wins'
  end

  def test_gender_from_sources
    dest_attr = DEFAULT_DEST_ATTR.dup
    client_sources = [
      {Gender: nil, DateUpdated: 3.days.ago},
      {Gender: '99', DateUpdated: 2.days.ago}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal '99', dest_attr[:Gender], 'Gender nil overwritten if something is non-blank'

    dest_attr = DEFAULT_DEST_ATTR.dup
    dest_attr[:Gender] = '3'
    client_sources = [
      {Gender: '99', DateUpdated: 3.days.ago},
      {Gender: '8', DateUpdated: 2.days.ago}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal '3', dest_attr[:Gender], 'only update gender known value if some client is a known value'

    dest_attr = DEFAULT_DEST_ATTR.dup
    dest_attr[:Gender] = '3'
    client_sources = [
      {Gender: '1', DateUpdated: 1.day.ago},
      {Gender: '2', DateUpdated: 2.days.ago}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal '1', dest_attr[:Gender], 'newest known value overwrites'

    dest_attr = DEFAULT_DEST_ATTR.dup
    dest_attr[:Gender] = '4'
    client_sources = [
      {Gender: '1', DateUpdated: 2.days.ago},
      {Gender: '4', DateUpdated: 1.days.ago}
    ]
    GrdaWarehouse::Tasks::ClientCleanup.update_dest_attr_from_sources(dest_attr, client_sources)
    assert_equal '4', dest_attr[:Gender], 'newest known value wins'
  end

end
