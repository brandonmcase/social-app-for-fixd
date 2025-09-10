require 'rails_helper'

RSpec.describe Rating, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:post) }
  end

  describe 'validations' do
    subject { build(:rating) }

    it { should validate_inclusion_of(:rating).in_array([ 1, 2, 3, 4, 5 ]) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:post_id) }
  end

  describe 'callbacks' do
    let(:user) { create(:user) }
    let(:post) { create(:post, user: user) }

    describe 'after_commit' do
      context 'on create' do
        it 'updates post cached statistics' do
          expect(post).to receive(:with_lock).and_yield
          expect(post).to receive(:update!).with(
            rating_count: 1,
            average_rating: 4.0
          )

          create(:rating, user: user, post: post, rating: 4)
        end

        it 'calculates correct average rating' do
          create(:rating, user: user, post: post, rating: 3)
          create(:rating, user: create(:user), post: post, rating: 5)

          post.reload
          expect(post.average_rating).to eq(4.0)
          expect(post.rating_count).to eq(2)
        end

        it 'handles zero ratings correctly' do
          rating = create(:rating, user: user, post: post, rating: 4)
          rating.destroy

          post.reload
          expect(post.average_rating).to eq(0.0)
          expect(post.rating_count).to eq(0)
        end
      end

      context 'on update' do
        let!(:rating) { create(:rating, user: user, post: post, rating: 3) }

        it 'updates post cached statistics when rating changes' do
          expect(post).to receive(:with_lock).and_yield
          expect(post).to receive(:update!).with(
            rating_count: 1,
            average_rating: 5.0
          )

          rating.update!(rating: 5)
        end
      end

      context 'on destroy' do
        let!(:rating) { create(:rating, user: user, post: post, rating: 4) }

        it 'updates post cached statistics when rating is deleted' do
          expect(post).to receive(:with_lock).and_yield
          expect(post).to receive(:update!).with(
            rating_count: 0,
            average_rating: 0.0
          )

          rating.destroy
        end
      end
    end
  end

  describe 'scopes' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:post1) { create(:post, user: user1) }
    let(:post2) { create(:post, user: user1) }

    before do
      create(:rating, user: user1, post: post1, rating: 4)
      create(:rating, user: user2, post: post1, rating: 5)
      create(:rating, user: user1, post: post2, rating: 3)
    end

    it 'can find ratings by user' do
      user1_ratings = Rating.where(user: user1)
      expect(user1_ratings.count).to eq(2)
      expect(user1_ratings.pluck(:rating)).to contain_exactly(4, 3)
    end

    it 'can find ratings by post' do
      post1_ratings = Rating.where(post: post1)
      expect(post1_ratings.count).to eq(2)
      expect(post1_ratings.pluck(:rating)).to contain_exactly(4, 5)
    end
  end

  describe 'database constraints' do
    let(:user) { create(:user) }
    let(:post) { create(:post, user: user) }

    it 'prevents duplicate ratings from same user for same post' do
      create(:rating, user: user, post: post, rating: 4)

      expect {
        create(:rating, user: user, post: post, rating: 5)
      }.to raise_error(ActiveRecord::RecordInvalid, /User has already been taken/)
    end

    it 'allows different users to rate the same post' do
      user2 = create(:user)

      expect {
        create(:rating, user: user, post: post, rating: 4)
        create(:rating, user: user2, post: post, rating: 5)
      }.not_to raise_error
    end
  end

  describe 'rating value validation' do
    let(:user) { create(:user) }
    let(:post) { create(:post, user: user) }

    it 'accepts valid rating values' do
      [ 1, 2, 3, 4, 5 ].each do |rating_value|
        rating = build(:rating, user: user, post: post, rating: rating_value)
        expect(rating).to be_valid
      end
    end

    it 'rejects invalid rating values' do
      [ 0, 6, -1, 10 ].each do |invalid_rating|
        rating = build(:rating, user: user, post: post, rating: invalid_rating)
        expect(rating).not_to be_valid
        expect(rating.errors[:rating]).to include('is not included in the list')
      end
    end
  end
end
