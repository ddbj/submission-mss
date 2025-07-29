RSpec.configure do |config|
  config.before :each do
    Rails.root.glob('tmp/storage/*', &:rmtree)
  end
end
