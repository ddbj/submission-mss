FactoryBot.define do
  factory :contact_person do
    trait :alice do
      email       { 'alice+contact@example.com' }
      full_name   { 'Alice Liddell' }
      affiliation { 'Wonderland Inc.' }
    end
  end
end
