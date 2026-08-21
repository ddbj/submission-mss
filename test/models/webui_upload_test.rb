require 'test_helper'

class WebuiUploadTest < ActiveSupport::TestCase
  test 'from_params turns down a request that carries no file' do
    [nil, []].each do |files|
      assert_raises Upload::Malformed do
        WebuiUpload.from_params(files:)
      end
    end
  end

  test 'from_params turns down a signed ID we did not issue' do
    assert_raises Upload::Malformed do
      WebuiUpload.from_params(files: ['not-a-signed-id'])
    end
  end
end
