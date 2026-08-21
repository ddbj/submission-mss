require 'test_helper'

class UploadTest < ActiveSupport::TestCase
  test 'build_via turns down a way of uploading we do not have' do
    ['sftp', '', nil].each do |via|
      assert_raises Upload::Malformed do
        Upload.build_via(via:, user: users(:alice))
      end
    end
  end
end
