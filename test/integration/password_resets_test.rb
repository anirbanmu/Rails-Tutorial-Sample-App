require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end

  test "password reset" do
    get new_password_reset_path
    assert_template 'password_resets/new'

    # Invalid email
    post password_resets_path, params: {password_reset: {email: "garbage@garbage.com"}}
    assert_select 'div.alert-danger', count:1
    assert_template 'password_resets/new'

    # Valid email
    post password_resets_path, params: {password_reset: {email: @user.email}}
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_redirected_to root_url
    user = assigns(:user)
    follow_redirect!
    assert_select 'div.alert-info', count:1

    # Password reset form
    # Wrong email
    get edit_password_reset_path(user.reset_token, email: 'garbage@garbage.com')
    assert_redirected_to root_url

    # Inactive user
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)

    # Right email, wrong token
    get edit_password_reset_path(User.new_token, email: user.email)
    assert_redirected_to root_url

    # Valid reset link
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select "input[name=email][type=hidden][value=?]", user.email

    # Invalid password & confirmation
    patch password_reset_path(user.reset_token), params: {email: user.email, user: {password: 'foobaz', password_confirmation: 'foobar'}}
    assert_select 'div#error_explanation'

    # Empty password
    patch password_reset_path(user.reset_token), params: {email: user.email, user: {password: '', password_confirmation: ''}}
    assert_select 'div#error_explanation'

    # Valid
    patch password_reset_path(user.reset_token), params: {email: user.email, user: {password: 'foobaz', password_confirmation: 'foobaz'}}
    assert_redirected_to user
    follow_redirect!
    assert is_logged_in?
    assert_select 'div.alert-success', count:1
    assert_nil user.reload.reset_digest
  end

  test "expired_token" do
    get new_password_reset_path
    post password_resets_path, params: {password_reset: {email: @user.email}}

    user = assigns(:user)
    user.update_attribute(:reset_sent_at, 3.hours.ago)

    patch password_reset_path(user.reset_token), params: {email: user.email, user: {password: '', password_confirmation: ''}}
    assert_response :redirect
    follow_redirect!
    assert_template 'password_resets/new'
    assert_match /expired/i, response.body
  end

end