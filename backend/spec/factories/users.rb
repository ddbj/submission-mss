FactoryBot.define do
  factory :user do
    sequence(:openid_sub) {|i| "user:#{i}" }

    id_token {|user|
      uid = user.openid_sub.sub(':', '_')

      {
        sub:                user.openid_sub,
        preferred_username: uid,
        email:              "#{uid}@example.com"
      }
    }

    trait :alice do
      id_token {|user|
        {
          sub:                user.openid_sub,
          preferred_username: 'alice-liddell',
          email:              'alice+idp@example.com'
        }
      }
    end
  end
end
