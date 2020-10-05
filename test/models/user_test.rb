require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(name:"Example User",email:"user@example.com",
                    password: "foobar", password_confirmation: "foobar")
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "name should be present" do
    @user.name = "    "
    refute @user.valid?
  end

  test "email should be present" do
    @user.email = "     "
    refute @user.valid?
  end

  test "email should not be too long" do
    # Rails db max length for strings =255
    @user.email = "a"*244+"@example.com"
    refute @user.valid?
  end

  test "email validation should accept valid addresses" do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
    first.last@foo.jp alice+bob@baz.cn]
    valid_addresses.each do |email|
      @user.email = email
      assert @user.valid?, "#{email.inspect} should be valid"
    end

  end

  test "email validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
    foo@bar_baz.com foo@bar+baz.com foo@bar..com]
    invalid_addresses.each do |email|
      @user.email = email
      refute @user.valid?, "#{email.inspect} should be invalid"
    end
  end

  test "email addresses should be unique" do
    duplicate_user = @user.dup
    @user.save
    refute duplicate_user.valid?
  end

  test "emails should be saved as lowercase" do
    mixed_case_email = "FoO@ExAmpLE.cOM"
    @user.email = mixed_case_email
    @user.save
    assert_equal mixed_case_email.downcase, @user.reload.email
  end

  test "password should not be blank" do
    @user.password = @user.password_confirmation = "  " *6
    refute @user.valid?
  end

  test "password should have a minimum length" do
    @user.password = @user.password_confirmation = "a"*5
    refute @user.valid?
  end

  test "authenticated? should return false for a user with nil digest" do
    refute @user.authenticated?(" ")
  end
end
