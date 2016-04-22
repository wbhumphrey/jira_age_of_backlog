require_relative '../../lib/issue_writer'

RSpec.describe IssueWriter do
  it 'adds values for fields that do not exist in the issue' do
    issue = {}
    fields = [:key, :reopen_date]

    expect(subject.filter_issue(issue, fields)).to eq([nil, nil])
  end

  it 'filters the issue key' do
    issue = {'key' =>'TestKey', garbage: 'blargh'}
    fields = [:key]

    expect(subject.filter_issue(issue, fields)).to eq(['TestKey'])
  end

  it 'filters the reopen date' do
    issue = {'key' => 'TestKey', "fields" => {'customfield_13402' => {'value' => '2016-04-01T15:26:02.000-0600', 'garbage' => 'blargh'}}}
    fields = [:reopen_date]

    expect(subject.filter_issue(issue, fields)).to eq(['2016-04-01 15:26:02'])
  end

  it 'respects the order of the keys' do
    issue = {'key' => 'TestKey', "fields" => {'customfield_13402' => {'value' => '2016-04-01T15:26:02.000-0600', 'garbage' => 'blargh'}}}

    expect(subject.filter_issue(issue, [:reopen_date, :key])).to eq(['2016-04-01 15:26:02', 'TestKey'])
    expect(subject.filter_issue(issue, [:key, :reopen_date])).to eq(['TestKey', '2016-04-01 15:26:02'])
  end

  it 'concatenates array values' do
    issue = {'key' => 'TestKey', "fields" => {'components' => [{'name' => 'component1'}, {'name' => 'component2'}]}}
    fields = [:components]

    expect(subject.filter_issue(issue, fields)).to eq(['component1,component2'])
  end
end