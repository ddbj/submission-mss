require 'test_helper'

class ExtractionErrorTest < ActiveSupport::TestCase
  test 'the ids are the ones the schema lists' do
    schema = YAML.load_file(Rails.root.join('schema/openapi.yml'))

    assert_equal schema.dig('components', 'schemas', 'ExtractionError', 'properties', 'id', 'enum'), Extraction::Error::IDS.map(&:to_s)
  end

  test 'an id the frontend has no words for' do
    assert_raises ArgumentError do
      Extraction::Error.new(:something_else)
    end
  end
end
