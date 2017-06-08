require 'test_helper'

class MicropostsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @micropost = microposts(:orange)
  end

  test 'should redirect create when logged in' do
    assert_no_difference 'Micropost.count' do
      post microposts_path, params: {micropost: {content: "Garbage content"}}
    end
    assert_redirected_to login_url
  end

  test 'should redirect destroy when not logged in' do
    assert_no_difference 'Micropost.count' do
      delete micropost_path(@micropost)
    end
  end
end
