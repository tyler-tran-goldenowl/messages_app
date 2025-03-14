FactoryBot.define do
  factory :user do
    first_name { "MyString" }
    last_name { "MyString" }
    birthday { "2025-03-14" }
    location { "MyString" }
    timezone { "MyString" }
  end
end
