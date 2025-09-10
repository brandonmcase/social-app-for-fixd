require 'rails_helper'

RSpec.describe JwtDenylist, type: :model do
  describe 'table name' do
    it 'uses the correct table name' do
      expect(JwtDenylist.table_name).to eq('jwt_denylists')
    end
  end

  describe 'database operations' do
    it 'can be created' do
      jwt_denylist = JwtDenylist.create!(jti: 'test-jti', exp: 1.hour.from_now)
      expect(jwt_denylist).to be_persisted
      expect(jwt_denylist.id).to be_present
    end

    it 'can be updated' do
      jwt_denylist = JwtDenylist.create!(jti: 'test-jti', exp: 1.hour.from_now)
      new_exp = 2.hours.from_now
      jwt_denylist.update!(exp: new_exp)
      expect(jwt_denylist.reload.exp).to be_within(1.second).of(new_exp)
    end

    it 'can be deleted' do
      jwt_denylist = JwtDenylist.create!(jti: 'test-jti', exp: 1.hour.from_now)
      jwt_denylist_id = jwt_denylist.id
      jwt_denylist.destroy!
      expect(JwtDenylist.find_by(id: jwt_denylist_id)).to be_nil
    end
  end

  describe 'attributes' do
    let(:jwt_denylist) { build(:jwt_denylist) }

    it 'has a jti attribute' do
      expect(jwt_denylist).to respond_to(:jti)
    end

    it 'has an exp attribute' do
      expect(jwt_denylist).to respond_to(:exp)
    end
  end

  describe 'validations' do
    context 'when all attributes are present' do
      it 'is valid' do
        jwt_denylist = build(:jwt_denylist)
        expect(jwt_denylist).to be_valid
      end
    end

    context 'when jti is missing' do
      it 'is valid (no validations defined)' do
        jwt_denylist = build(:jwt_denylist, jti: nil)
        expect(jwt_denylist).to be_valid
      end
    end

    context 'when exp is missing' do
      it 'is valid (no validations defined)' do
        jwt_denylist = build(:jwt_denylist, exp: nil)
        expect(jwt_denylist).to be_valid
      end
    end
  end

  describe 'uniqueness' do
    it 'allows duplicate jti (no uniqueness validation)' do
      JwtDenylist.create!(jti: 'unique-jti', exp: 1.hour.from_now)
      duplicate = JwtDenylist.new(jti: 'unique-jti', exp: 2.hours.from_now)
      expect(duplicate).to be_valid
    end
  end
end
