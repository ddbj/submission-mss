require 'test_helper'
require 'fugit'

class RecurringScheduleTest < ActiveSupport::TestCase
  # Read at boot by the scheduler Solid Queue starts inside Puma, which aborts
  # on a job that is not there or a schedule it cannot read -- and the Puma
  # plugin answers a supervisor that exits by signalling Puma itself. A typo
  # here does not lose a sweep; it takes the site down at boot.
  test 'every environment schedules jobs that exist, at times that parse' do
    config = ActiveSupport::ConfigurationFile.parse(Rails.root.join('config/recurring.yml')).deep_symbolize_keys

    %i[production staging].each do |env|
      tasks = config.fetch(env)

      assert tasks.any?, "#{env} schedules nothing"

      tasks.each do |id, task|
        assert Object.const_defined?(task.fetch(:class)), "#{env}/#{id} names a job that is not there"

        # Solid Queue takes a cron and nothing else: 'every 2 hours' parses, as
        # a Fugit::Duration, and is turned down all the same.
        assert_kind_of Fugit::Cron, Fugit.parse(task.fetch(:schedule), multi: :fail),
                       "#{env}/#{id} is not scheduled at a time Solid Queue takes"
      end
    end
  end
end
