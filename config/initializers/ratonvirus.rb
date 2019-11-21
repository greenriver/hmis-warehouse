# config/initializers/ratonvirus.rb
Ratonvirus.configure do |config|
  config.scanner = :clamby
  config.storage = :carrierwave
end
