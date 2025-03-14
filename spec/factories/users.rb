FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    birthdate { Faker::Date.birthday }
    location { 'New York, NY' }

    trait :birthday_today do
      birthdate { Date.today }
    end
  end
end
