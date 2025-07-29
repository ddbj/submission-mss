FactoryBot.define do
  factory :user do
    sequence(:uid) { "user_#{_1}" }

    email { "#{uid}@example.com" }

    trait :alice do
      uid { 'alice' }
    end
  end
end
