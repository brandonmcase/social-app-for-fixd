FactoryBot.define do
  factory :post do
    title { Faker::Lorem.sentence(word_count: 3) }
    body { Faker::Lorem.paragraph(sentence_count: 5) }
    user
    view_count { 0 }
    metadata { {} }
    average_rating { 0.0 }
    rating_count { 0 }

    trait :with_metadata do
      metadata do
        {
          category: Faker::Lorem.word,
          language: 'en',
          source: 'web',
          tags: Faker::Lorem.words(number: 3).join(',')
        }
      end
    end

    trait :featured do
      metadata { { featured: true } }
    end

    trait :deleted do
      deleted_at { Time.current }
    end

    trait :with_rating do
      average_rating { rand(1.0..5.0).round(2) }
      rating_count { rand(1..100) }
    end

    trait :with_views do
      view_count { rand(1..1000) }
    end
  end
end
