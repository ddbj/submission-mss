FactoryBot.define do
  factory :submission do
    sequence(:mass_id) { "NSUB#{_1.to_s.rjust(6, '0')}" }

    tpa            { [true, false].sample }
    entries_count  { rand(0..100) }
    hold_date      { [nil, Date.current.advance(months: 1)].sample }
    sequencer      { Submission.sequencer.values.sample }
    data_type      { Submission.data_type.values.sample }
    description    { 'some description' }
    email_language { Submission.email_language.values.sample }
  end
end
