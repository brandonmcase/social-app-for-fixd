FactoryBot.define do
  factory :rating do
    association :user
    association :post
    rating { rand(1..5) }

    trait :five_star do
      rating { 5 }
    end

    trait :four_star do
      rating { 4 }
    end

    trait :three_star do
      rating { 3 }
    end

    trait :two_star do
      rating { 2 }
    end

    trait :one_star do
      rating { 1 }
    end
  end
end
