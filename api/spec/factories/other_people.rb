FactoryBot.define do
  factory :other_person do
    sequence :position

    trait :bob do
      email     { 'bob@bar.example.com' }
      full_name { 'Bob' }
    end

    trait :carol do
      email     { 'carol@baz.example.com' }
      full_name { 'Carol' }
    end
  end
end
