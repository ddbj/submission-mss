require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'from_claims! makes a newcomer with the address given' do
    user = User.from_claims!(uid: 'newcomer', email: 'n@example.com')

    assert_predicate user, :persisted?
    assert_equal 'n@example.com', user.email
  end

  test 'from_claims! finds an existing user and leaves their address alone' do
    assert_no_difference -> { User.count } do
      assert_equal users(:alice), User.from_claims!(uid: 'alice', email: 'alice@elsewhere.example.com')
    end

    assert_equal 'alice@example.com', users(:alice).reload.email
  end

  test 'from_claims! finds an existing user without an address' do
    assert_equal users(:alice), User.from_claims!(uid: 'alice', email: nil)
  end

  test 'from_claims! makes no newcomer without an address' do
    [nil, '', ['n@example.com']].each do |email|
      assert_raises(User::IncompleteClaims) { User.from_claims!(uid: 'newcomer', email:) }
    end

    assert_nil User.find_by(uid: 'newcomer')
  end

  test 'from_claims! wants a uid' do
    [nil, '', 42].each do |uid|
      assert_raises(User::IncompleteClaims) { User.from_claims!(uid:, email: 'n@example.com') }
    end
  end
end
