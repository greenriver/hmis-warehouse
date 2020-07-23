namespace :secrets do
  desc "Rotate out the first placeholder secret for a real one"
  task :init, [] => [:environment] do |t, args|
    # Rotate out the first placeholder secret for a real one
    Encryption::Util.init!
  end

  # Copy cleartext into encrypted fields
  # THIS DOES NOT ERASE cleartext
  # Erasing cleartext is in a separate step
  desc "copy over cleartext"
  task :copy_cleartext, [] => [:environment] do |t, args|
    PIIAttributeSupport.allowed_pii_classes.each do |klass|
      klass.find_each do |person|
        klass.encrypted_attributes.keys.each do |cleartext_column|
          if person.read_attribute(cleartext_column).present?
            person.send("#{cleartext_column}=", person.read_attribute(cleartext_column))
          end
        end
        person.save!
      end
    end
  end

  desc "Wipe cleartext"
  task :wipe, [] => [:environment] do |t, args|
    PIIAttributeSupport.allowed_pii_classes.each do |klass|
      klass.find_each do |person|
        klass.encrypted_attributes.keys.each do |cleartext_column|
          # assumes we're always keeping cleartext column for installations
          # not doing PII encryption
          person.write_attribute(cleartext_column, nil)
        end
        person.save!
      end
    end
  end

  desc "Set Up for Testing"
  task :test, [] => [:environment] do |t, args|
    raise "Cannot do this outside of dev" unless Rails.env.development?

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

  desc "Rotate secrets"
  task :rotate, [] => [:environment] do |t, args|
    Encryption::Secret.current.rotate! do |old_secret, new_secret|
      Rails.logger.info "Rotating data now"

      old_key = old_secret.plaintext_key
      new_key = new_secret.plaintext_key

      Rails.logger.info "Rotating clients"

      PIIAttributeSupport.allowed_pii_classes.each do |klass|
        klass.find_each do |client|
          client.rekey!(old_key, new_key)
        end
      end
    end
  end

  desc "Show secret versions"
  task :show_versions, [] => [:environment] do |t, args|
    ap Encryption::Util.history
  end
end
