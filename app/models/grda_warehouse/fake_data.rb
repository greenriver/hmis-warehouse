require 'faker'
class GrdaWarehouse::FakeData < GrdaWarehouseBase
  serialize :map, JSON
  serialize :client_ids, JSON

  # Fetch the appropriate faked value for a given field.
  # Return an existing match if one exists or create a new one,
  # save it to the history and return it
  def fetch(field_name:, real_value:)
    field_name = field_name.to_s # the JSONification turns these into strings
    return real_value unless fake_patterns[field_name.to_sym].present?
    if fake_value = map.try(:[], field_name).try(:[], real_value)
      return fake_value
    else
      fake_value = fake_patterns[field_name.to_sym].call(real_value)
      add_fake_value(
        field_name: field_name,
        real_value: real_value,
        fake_value: fake_value
      )
    end
    return fake_value
  end

  def add_fake_value(field_name:, real_value:, fake_value:)
    return unless real_value.present?
    field_name = field_name.to_s
    self[:map] ||= {}
    self[:map][field_name] ||= {}
    self[:map][field_name][real_value] = fake_value
  end

  def fake_patterns
    @fake_patterns ||= {
      FirstName:  -> (value) { fake_name(type: :first) },
      LastName: -> (value) { fake_name(type: :last) },
      SSN: -> (value) { fake_ssn(value) if value.present?},
      DOB: -> (value) {
        Faker::Date.between(70.years.ago, 1.years.ago) if value.present?
      },
      PersonalID: -> (value) { SecureRandom.uuid.gsub('-', '') },
      UserID: -> (value) { Faker::Internet.user_name(5..8) },
      CoCCode: -> (value) { "#{Faker::Address.state_abbr}-#{Faker::Number.number(3)}" },
      ProjectName: -> (value) { fake_location },
      ProjectCommonName: -> (value) { fake_location },
      OrganizationName: -> (value) { fake_location },
      OrganizationCommonName: -> (value) { fake_location },
      SourceContactEmail: -> (value) { Faker::Internet.safe_email},
      SourceContactFirst: -> (value) { fake_name(type: :first) },
      SourceContactLast: -> (value) { fake_name(type: :last) },
      SourceContactPhone: -> (value) { Faker::PhoneNumber.cell_phone },
      Address: -> (value) { Faker::Address.street_address },
      City: -> (value) { Faker::Address.city },
      State: -> (value) { Faker::Address.state_abbr },
      ZIP: -> (value) { Faker::Address.zip },
      LastPermanentStreet: -> (value) { Faker::Address.street_address },
      LastPermanentCity: -> (value) { Faker::Address.city },
      LastPermanentState: -> (value) { Faker::Address.state_abbr },
      LastPermanentZIP: -> (value) { Faker::Address.zip },
      OtherDestination: -> (value) { if value.present? then Faker::Hipster.sentence(3) else nil end},
      OtherDisposition: -> (value) {if value.present? then Faker::Hipster.sentence(2) else nil end},
      OtherInsuranceIdentify: -> (value) {if value.present? then Faker::TwinPeaks.location << ' Health' else nil end},
    }
  end

  def fake_name(type:)
    @fake_names ||= CSV.read(Rails.root.join.to_s << '/db/fake_data/names.csv').drop(1).uniq
    case type
    when :first
      @fake_names.sample.last
    when :last
      @fake_names.sample.first
    end
  end

  def fake_location
    @fake_locations ||= CSV.read(Rails.root.join.to_s << '/db/fake_data/places.csv').drop(1).uniq
    @fake_locations.sample.first
  end

  # somewhat elaborate SSN faking to make the fake data look more like the real data
  def fake_ssn(value)
    if SimilarityMetric::SocialSecurityNumber::FAKES_RX === value
      # make a different, but also fake, SSN
      v = value
      @randos ||= [
        *(1..10).map{ -> { rand(0..9).to_s * rand(3..9) } },  # mostly of this sort (why not)
        *(1..5).map{ -> { '123456789'[0...rand(4..9)] } },    # then a lot of these
        -> {'078051120'}                                      # and one of these
      ]
      while v == value
        v = @randos.sample.()
      end
      v
    else
      Faker::Number.number(9)
    end
  end
end