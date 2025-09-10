require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    let(:user) { build(:user) }

    context 'when all attributes are valid' do
      it 'is valid' do
        expect(user).to be_valid
      end
    end

    context 'email validation' do
      it 'is invalid without an email' do
        user.email = nil
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it 'is invalid with a blank email' do
        user.email = ''
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it 'is invalid with an invalid email format' do
        user.email = 'invalid_email'
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('is invalid')
      end

      it 'is valid with a valid email format' do
        user.email = 'user@example.com'
        expect(user).to be_valid
      end

      it 'is invalid with duplicate email' do
        create(:user, email: 'test@example.com')
        user.email = 'test@example.com'
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('has already been taken')
      end
    end

    context 'username validation' do
      it 'is invalid without a username' do
        user.username = nil
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include("can't be blank")
      end

      it 'is invalid with a blank username' do
        user.username = ''
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include("can't be blank")
      end

      it 'is invalid with username longer than 50 characters' do
        user.username = 'a' * 51
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include('is too long (maximum is 50 characters)')
      end

      it 'is valid with username exactly 50 characters' do
        user.username = 'a' * 50
        expect(user).to be_valid
      end

      it 'is invalid with duplicate username' do
        create(:user, username: 'testuser')
        user.username = 'testuser'
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include('has already been taken')
      end

      it 'is invalid with duplicate username (case insensitive)' do
        create(:user, username: 'TestUser')
        user.username = 'testuser'
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include('has already been taken')
      end

      it 'is invalid with username containing special characters' do
        user.username = 'user@name'
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include('is invalid')
      end

      it 'is invalid with username containing spaces' do
        user.username = 'user name'
        expect(user).not_to be_valid
        expect(user.errors[:username]).to include('is invalid')
      end

      it 'is valid with username containing only letters, numbers, and underscores' do
        user.username = 'user_name123'
        expect(user).to be_valid
      end

      it 'is valid with username containing uppercase letters' do
        user.username = 'UserName'
        expect(user).to be_valid
      end
    end

    context 'password validation' do
      it 'is invalid without a password' do
        user.password = nil
        user.password_confirmation = nil
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("can't be blank")
      end

      it 'is invalid with a blank password' do
        user.password = ''
        user.password_confirmation = ''
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("can't be blank")
      end

      it 'is invalid with password shorter than 8 characters' do
        user.password = '1234567'
        user.password_confirmation = '1234567'
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('is too short (minimum is 8 characters)')
      end

      it 'is valid with password exactly 8 characters' do
        user.password = '12345678'
        user.password_confirmation = '12345678'
        expect(user).to be_valid
      end

      it 'is invalid when password and password_confirmation do not match' do
        user.password = 'password123'
        user.password_confirmation = 'different123'
        expect(user).not_to be_valid
        expect(user.errors[:password_confirmation]).to include("doesn't match Password")
      end
    end
  end

  describe 'devise modules' do
    it 'includes database_authenticatable' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it 'includes registerable' do
      expect(User.devise_modules).to include(:registerable)
    end

    it 'includes recoverable' do
      expect(User.devise_modules).to include(:recoverable)
    end

    it 'includes validatable' do
      expect(User.devise_modules).to include(:validatable)
    end

    it 'includes jwt_authenticatable' do
      expect(User.devise_modules).to include(:jwt_authenticatable)
    end
  end

  describe 'jwt revocation strategy' do
    it 'uses JwtDenylist as revocation strategy' do
      expect(User.jwt_revocation_strategy).to eq(JwtDenylist)
    end
  end

  describe 'database operations' do
    it 'can be created' do
      user = User.create!(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        password_confirmation: 'password123'
      )
      expect(user).to be_persisted
      expect(user.id).to be_present
    end

    it 'can be updated' do
      user = create(:user)
      user.update!(username: 'newusername')
      expect(user.reload.username).to eq('newusername')
    end

    it 'can be deleted' do
      user = create(:user)
      user_id = user.id
      user.destroy!
      expect(User.find_by(id: user_id)).to be_nil
    end
  end

  describe 'password encryption' do
    it 'encrypts the password' do
      user = User.create!(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        password_confirmation: 'password123'
      )
      expect(user.encrypted_password).to be_present
      expect(user.encrypted_password).not_to eq('password123')
    end

    it 'can authenticate with correct password' do
      user = User.create!(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        password_confirmation: 'password123'
      )
      expect(user.valid_password?('password123')).to be true
    end

    it 'cannot authenticate with incorrect password' do
      user = User.create!(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        password_confirmation: 'password123'
      )
      expect(user.valid_password?('wrongpassword')).to be false
    end
  end
end
