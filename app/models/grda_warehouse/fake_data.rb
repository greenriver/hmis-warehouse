###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

    fake_value = map.try(:[], field_name).try(:[], real_value)
    return fake_value if fake_value

    fake_value = fake_patterns[field_name.to_sym].call(real_value)
    add_fake_value(
      field_name: field_name,
      real_value: real_value,
      fake_value: fake_value,
    )
    fake_value
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
      FirstName: ->(_value) { fake_name(type: :first) },
      LastName: ->(_value) { fake_name(type: :last) },
      SSN: ->(value) { fake_ssn(value).to_s[0, 9] if value.present? },
      DOB: ->(value) {
        value = value&.to_date
        if value.present? && value.is_a?(Date)
          # If we have a birthday, shift it some random amount, but not so much that we
          # drastically change life stage
          value + (-600..600).to_a.sample
          # Faker::Date.between(from: 70.years.ago, to: 1.years.ago)
        end
      },
      PersonalID: ->(value) { Digest::MD5.hexdigest(value&.to_s) },
      UserID: ->(_value) { Faker::Internet.user_name(specifier: 5..8) },
      CoCCode: ->(_value) do
        rc = ENV['RELEVANT_COC_STATE']
        if rc
          HUD.cocs.keys.select { |c| c.starts_with?(rc) }.sample
        else
          HUD.cocs.keys.sample
        end
      end,
      ProjectName: ->(_value) { fake_location },
      ProjectCommonName: ->(_value) { fake_location },
      OrganizationName: ->(_value) { fake_location },
      OrganizationCommonName: ->(_value) { fake_location },
      SourceContactEmail: ->(_value) { Faker::Internet.safe_email },
      SourceContactFirst: ->(_value) { fake_name(type: :first) },
      SourceContactLast: ->(_value) { fake_name(type: :last) },
      SourceContactPhone: ->(_value) { Faker::PhoneNumber.cell_phone },
      Address: ->(_value) { Faker::Address.street_address },
      City: ->(_value) { Faker::Address.city },
      State: ->(_value) { Faker::Address.state_abbr },
      ZIP: ->(_value) { Faker::Address.zip },
      LastPermanentStreet: ->(_value) { Faker::Address.street_address },
      LastPermanentCity: ->(_value) { Faker::Address.city },
      LastPermanentState: ->(_value) { Faker::Address.state_abbr },
      LastPermanentZIP: ->(_value) { Faker::Address.zip },
      OtherDestination: ->(value) { Faker::Hipster.sentence(word_count: 3) if value.present? },
      OtherDisposition: ->(value) { Faker::Hipster.sentence(word_count: 2) if value.present? },
      OtherInsuranceIdentify: ->(value) { Faker::TvShows::TwinPeaks.location + ' Health' if value.present? },
      OtherIncomeSourceIdentify: ->(value) { Faker::TvShows::TwinPeaks.location if value.present? },
      OtherBenefitsSourceIdentify: ->(value) { Faker::TvShows::TwinPeaks.location if value.present? },
      OtherTypeProvided: ->(value) { Faker::TvShows::TwinPeaks.location if value.present? },
      Address1: ->(value) { Faker::Address.street_address if value.present? },
      Address2: ->(value) { Faker::Address.street_address if value.present? },
      UserFirstName: ->(_value) { fake_name(type: :first) },
      UserLastName: ->(_value) { fake_name(type: :last) },
      UserEmail: ->(_value) { Faker::Internet.safe_email },
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
        *(1..10).map { -> { rand(0..9).to_s * rand(3..9) } },  # mostly of this sort (why not)
        *(1..5).map { -> { '123456789'[0...rand(4..9)] } },    # then a lot of these
        -> { '078051120' },                                     # and one of these
      ]

      v = @randos.sample.call while v == value
      v
    else
      Faker::Number.number(digits: 9)
    end
  end
end
