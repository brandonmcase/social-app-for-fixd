FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    username { Faker::Internet.username(specifier: 8..20).gsub(/[^a-zA-Z0-9_]/, '_') }
    password { 'password123' }
    password_confirmation { 'password123' }

    trait :with_different_email do
      email { Faker::Internet.email }
    end

    trait :with_different_username do
      username { Faker::Internet.username(specifier: 8..20).gsub(/[^a-zA-Z0-9_]/, '_') }
    end

    trait :with_short_password do
      password { '1234567' }
      password_confirmation { '1234567' }
    end

    trait :with_long_username do
      username { 'a' * 51 }
    end

    trait :with_special_characters_username do
      username { 'user@name' }
    end

    trait :with_spaces_username do
      username { 'user name' }
    end

    trait :with_valid_special_username do
      username { 'user_name123' }
    end

    trait :with_uppercase_username do
      username { 'UserName' }
    end
  end
end
