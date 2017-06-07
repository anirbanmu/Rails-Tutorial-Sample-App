require 'test_helper'

class UsersIndexTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:michael)
    @non_admin = users(:archer)
  end

  test "index including pagination as non-admin" do
    log_in_as(@non_admin)
    get users_path
    total_pages = assigns[:users].total_pages

    # Add unactivated user
    assert_difference 'User.count', 1 do
      post signup_path, params: { user: {name: "Example User",
                                         email: "user@example.com",
                                         password: "password",
                                         password_confirmation: "password"}}
    end
    unactivated_user = assigns(:user)

    for n in 1..total_pages
      get users_path(page: n)
      assert_template 'users/index'
      assert_select 'div.pagination', count: 2

      # Make sure unactivated user is never listed
      assert_select 'a[href=?]', user_path(unactivated_user), count:0

      User.where(activated: true).paginate(page: n).each do |user|
        assert_select 'a[href=?]', user_path(user), text: user.name
      end
    end
  end

  test "index incuding pagination & delete links for admin" do
    log_in_as(@admin)
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination', count: 2
    User.paginate(page: 1).each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name
      unless user == @admin
        assert_select 'a[href=?]', user_path(user), text: 'delete'
      end
    end

    assert_difference 'User.count', -1 do
      delete user_path(@non_admin)
    end
  end
end
