FactoryBot.define do
  factory :message do
    user
    sent_at { nil }
    message_type { :birthday }

    trait :birthday do
      message_type { :birthday }
    end
  end
end
