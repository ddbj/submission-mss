FactoryBot.define do
  factory :other_person do
    sequence :position

    trait :bob do
      email     { 'bob@example.com' }
      full_name { 'Bob' }
    end

    trait :carol do
      email     { 'carol@example.com' }
      full_name { 'Carol' }
    end
  end
end
