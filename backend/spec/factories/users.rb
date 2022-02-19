FactoryBot.define do
  factory :user do
    sequence(:openid_sub) {|i| "user:#{i}" }

    trait :alice do
      id_token {
        {
          preferred_username: 'alice-liddell',
          email:              'alice+idp@example.com'
        }
      }
    end
  end
end
