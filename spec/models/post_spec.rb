require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      expect(Post.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'validates presence of title' do
      post = build(:post, title: nil)
      expect(post).not_to be_valid
      expect(post.errors[:title]).to include("can't be blank")
    end

    it 'validates presence of body' do
      post = build(:post, body: nil)
      expect(post).not_to be_valid
      expect(post.errors[:body]).to include("can't be blank")
    end

    it 'validates title length is at most 100 characters' do
      post = build(:post, title: 'a' * 101)
      expect(post).not_to be_valid
      expect(post.errors[:title]).to include("is too long (maximum is 100 characters)")
    end

    it 'validates body length is at most 1000 characters' do
      post = build(:post, body: 'a' * 1001)
      expect(post).not_to be_valid
      expect(post.errors[:body]).to include("is too long (maximum is 1000 characters)")
    end
  end

  describe 'scopes' do
    describe '.active' do
      let!(:active_post) { create(:post) }
      let!(:deleted_post) { create(:post, :deleted) }

      it 'returns only non-deleted posts' do
        expect(Post.active).to include(active_post)
        expect(Post.active).not_to include(deleted_post)
      end
    end
  end

  describe 'instance methods' do
    describe '#username' do
      let(:user) { create(:user, username: 'testuser') }
      let(:post) { create(:post, user: user) }

      it 'returns the username of the associated user' do
        expect(post.username).to eq('testuser')
      end
    end
  end

  describe 'database columns' do
    it 'has the correct columns' do
      expect(Post.column_names).to include(
        'id', 'title', 'body', 'user_id', 'deleted_at', 'view_count',
        'metadata', 'jsonb', 'average_rating', 'rating_count', 'created_at', 'updated_at'
      )
    end

    it 'has correct column types' do
      expect(Post.columns_hash['title'].type).to eq(:string)
      expect(Post.columns_hash['body'].type).to eq(:string)
      expect(Post.columns_hash['user_id'].type).to eq(:integer)
      expect(Post.columns_hash['view_count'].type).to eq(:integer)
      expect(Post.columns_hash['metadata'].type).to eq(:jsonb)
      expect(Post.columns_hash['average_rating'].type).to eq(:decimal)
      expect(Post.columns_hash['rating_count'].type).to eq(:integer)
    end
  end

  describe 'default values' do
    let(:post) { Post.new(title: 'Test', body: 'Test body', user: create(:user)) }

    it 'sets default values correctly' do
      post.save!
      expect(post.view_count).to eq(0)
      expect(post.metadata).to eq({})
      expect(post.average_rating).to eq(0.0)
      expect(post.rating_count).to eq(0)
    end
  end

  describe 'soft delete functionality' do
    let(:post) { create(:post) }

    it 'can be soft deleted' do
      expect(post.deleted_at).to be_nil
      post.update!(deleted_at: Time.current)
      expect(post.deleted_at).not_to be_nil
    end

    it 'is excluded from active scope when deleted' do
      post.update!(deleted_at: Time.current)
      expect(Post.active).not_to include(post)
    end
  end

  describe 'metadata functionality' do
    let(:post) { create(:post, :with_metadata) }

    it 'can store metadata as JSON' do
      expect(post.metadata).to be_a(Hash)
      expect(post.metadata['category']).to be_present
      expect(post.metadata['language']).to eq('en')
    end

    it 'can store featured metadata' do
      featured_post = create(:post, :featured)
      expect(featured_post.metadata['featured']).to be true
    end
  end

  describe 'rating functionality' do
    let(:post) { create(:post, :with_rating) }

    it 'can store average rating' do
      expect(post.average_rating).to be > 0
      expect(post.average_rating).to be <= 5.0
    end

    it 'can store rating count' do
      expect(post.rating_count).to be > 0
    end
  end

  describe 'view count functionality' do
    let(:post) { create(:post, :with_views) }

    it 'can track view count' do
      expect(post.view_count).to be > 0
    end

    it 'can increment view count' do
      initial_count = post.view_count
      post.increment!(:view_count)
      expect(post.view_count).to eq(initial_count + 1)
    end
  end

  describe 'factory' do
    it 'creates a valid post' do
      post = build(:post)
      expect(post).to be_valid
    end

    it 'creates a post with metadata' do
      post = create(:post, :with_metadata)
      expect(post.metadata).to be_present
    end

    it 'creates a featured post' do
      post = create(:post, :featured)
      expect(post.metadata['featured']).to be true
    end

    it 'creates a deleted post' do
      post = create(:post, :deleted)
      expect(post.deleted_at).to be_present
    end
  end
end
