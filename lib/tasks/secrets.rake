namespace :secrets do
  desc "Rotate out the first placeholder secret for a real one"
  task :init, [] => [:environment] do |t, args|
    # Rotate out the first placeholder secret for a real one
    Encryption::Util.init!
  end

  desc "copy over cleartext"
  task :copy_cleartext, [] => [:environment] do |t, args|
    GrdaWarehouse::Hud::Client.transaction do
      # Copy cleartext into encrypted fields
      # THIS DOES NOT ERASE cleartext
      # Erasing cleartext will be a separate step when we're sure this is
      # working
      GrdaWarehouse::Hud::Client.find_each do |client|
        client.FirstName = client.read_attribute(:FirstName) if client.read_attribute(:FirstName).present?
        client.LastName = client.read_attribute(:LastName) if client.read_attribute(:LastName).present?
        client.MiddleName = client.read_attribute(:MiddleName) if client.read_attribute(:MiddleName).present?
        client.SSN = client.read_attribute(:SSN) if client.read_attribute(:SSN).present?
        client.NameSuffix = client.read_attribute(:NameSuffix) if client.read_attribute(:NameSuffix).present?
        client.save!
      end
    end
  end

  desc "Wipe cleartext"
  task :wipe, [] => [:environment] do |t, args|
    GrdaWarehouse::Hud::Client.transaction do
      GrdaWarehouse::Hud::Client.find_each do |client|
        client.write_attribute(:FirstName, nil)
        client.write_attribute(:LastName, nil)
        client.write_attribute(:MiddleName, nil)
        client.write_attribute(:SSN, nil)
        client.write_attribute(:NameSuffix, nil)
        client.save!
      end
    end
  end

  desc "Set Up for Testing"
  task :test, [] => [:environment] do |t, args|
    raise "cannot do this outside of dev" unless Rails.env.development?

    GrdaWarehouse::Hud::Client.allow_pii!

    GrdaWarehouse::Hud::Client.find_each do |client|
      client.write_attribute(:FirstName, ['Sam', 'Jon', 'Joe', 'Lisa', 'phil'].sample)
      client.write_attribute(:LastName, ['Johnson', 'White', 'McDonald'].sample)
      client.write_attribute(:MiddleName, ['James', 'P', 'K'].sample)
      client.write_attribute(:SSN, "12371#{1000+Random.rand(8999)}")
      client.write_attribute(:NameSuffix, ['Sr.', 'Jr.'].sample)
      client.save!
    end

    Rake::Task['secrets:copy_cleartext'].invoke
    Rake::Task['secrets:wipe'].invoke
  end

  desc "Rotate secrets. This doesn't update any data"
  task :rotate, [] => [:environment] do |t, args|
    Encryption::Secret.current.rotate! do |old_secret, new_secret|
      Rails.logger.info "Rotating data now"

      old_key = old_secret.plaintext_key
      new_key = new_secret.plaintext_key

      Rails.logger.info "Rotating clients"
      GrdaWarehouse::Hud::Client.find_each do |client|
        client.rekey!(old_key, new_key)
      end
    end
  end

  desc "Show secret versions"
  task :show_versions, [] => [:environment] do |t, args|
    ap Encryption::Util.history
  end
end
