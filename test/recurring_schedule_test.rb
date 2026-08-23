require 'test_helper'
require 'fugit'

class RecurringScheduleTest < ActiveSupport::TestCase
  # Read at boot by the scheduler Solid Queue starts inside Puma, which aborts
  # on a job that is not there or a schedule it cannot read -- and the Puma
  # plugin answers a supervisor that exits by signalling Puma itself. A typo
  # here does not lose a sweep; it takes the site down at boot.
  def config
    ActiveSupport::ConfigurationFile.parse(Rails.root.join('config/recurring.yml')).deep_symbolize_keys
  end

  test 'every environment schedules jobs that exist, at times that parse' do
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

  # Anchors sit at the top level alongside the environments, and for any
  # environment it does not find there Solid Queue takes the whole file as the
  # schedule. A task written directly at that level -- rather than inside one --
  # is picked up, and runs in development and in test, where nobody is looking.
  test 'nothing at the top level is a task in its own right' do
    config.each do |key, value|
      assert_not value.key?(:schedule), "#{key} is scheduled at the top level, which runs it in every environment"
    end
  end
end
