FactoryBot.define do
  factory :jwt_denylist do
    jti { SecureRandom.uuid }
    exp { 1.hour.from_now }

    trait :expired do
      exp { 1.hour.ago }
    end

    trait :with_different_jti do
      jti { SecureRandom.uuid }
    end

    trait :with_different_exp do
      exp { 2.hours.from_now }
    end
  end
end
