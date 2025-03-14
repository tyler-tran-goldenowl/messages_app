FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    birthdate { Faker::Date.birthday(min_age: 18, max_age: 65) }
    location { Faker::Address.city }
    timezone { ActiveSupport::TimeZone.all.sample.name }
  end
end
