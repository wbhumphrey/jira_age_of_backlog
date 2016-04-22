require_relative '../../lib/jira_issue'

RSpec.describe JiraIssue do
  subject {JiraIssue.new(issue)}
  let(:issue) {double('issue')}

  context '#last_opened_date' do
    let(:created_date) {'2016-03-03T13:46:47.569-0700'}
    let(:reopen_date) {'2016-03-10T13:46:47.569-0700'}
    let(:attrs) {
      {
          'fields' => {
              'created' => created_date
          },
          'changelog' => {
              'histories' => [
                  {
                      'created' => reopen_date,
                      'items' => [
                          'field' => 'status',
                          'fromString' => 'Closed',
                          'toString' => 'Some Status'
                      ]
                  }
              ]
          }
      }
    }

    before(:each) do
      allow(issue).to receive(:attrs) {attrs}
    end

    it 'defaults to the creation date if the issue has never been reopened' do
      attrs['changelog']['histories'] = []

      expect(subject.last_opened_date(DateTime.parse('2016-03-04'))).to eq(DateTime.parse(created_date))
    end

    it 'finds the last time that an issue was moved from closed to any other status' do
      expect(subject.last_opened_date(DateTime.parse('2016-03-12'))).to eq(DateTime.parse(reopen_date))
    end

    it 'returns nil if the creation date is in the future' do
      expect(subject.last_opened_date(DateTime.parse('2016-03-01'))).to be_nil
    end

    it 'does not recognize a status change from closed to closed as a reopen' do
      attrs['changelog']['histories'].first['items'].first['toString'] = 'Closed'

      expect(subject.last_opened_date(DateTime.parse('2016-03-12'))).to eq(DateTime.parse(created_date))
    end
  end

  context '#next_closed_date' do
    let(:closed_date) {'2016-03-03T13:46:47.569-0700'}
    let(:attrs) {
      {
          'changelog' => {
              'histories' => [
                  {
                      'created' => closed_date,
                      'items' => [
                          'field' => 'status',
                          'fromString' => 'Some Date',
                          'toString' => 'Closed'
                      ]
                  },
                  {
                      'created' => '2016-03-01T13:46:47.569-0700',
                      'items' => [
                          'field' => 'status',
                          'fromString' => 'Some Date',
                          'toString' => 'Closed'
                      ]
                  }
              ]
          }
      }
    }

    before(:each) do
      allow(issue).to receive(:attrs) {attrs}
    end

    it 'finds the first time that an issue was closed after a given date' do
      expect(subject.next_closed_date(DateTime.parse('2016-03-02'))).to eq(DateTime.parse(closed_date))
      expect(subject.next_closed_date(DateTime.parse('2016-02-02'))).to eq(DateTime.parse('2016-03-01T13:46:47.569-0700'))
    end

    it 'returns nil if the issue has been closed since the given date' do
      expect(subject.next_closed_date(DateTime.parse('2016-03-05'))).to be_nil
    end
  end

  context '#days_since_opened' do
    let(:created_date) {'2016-03-03'}
    let(:shelved_date) {'2016-03-05'}
    let(:reopen_date) {'2016-03-10'}
    let(:closed_date) {'2016-03-15'}
    let(:attrs) {
      {
          'fields' => {
              'created' => created_date
          },
          'changelog' => {
              'histories' => [
                  {
                      'created' => shelved_date,
                      'items' => [
                          {
                              'field' => 'resolution',
                              'fromString' => '',
                              'toString' => 'Shelved'
                          },
                          {
                              'field' => 'status',
                              'fromString' => 'Open',
                              'toString' => 'Closed'
                          },
                      ]
                  },
                  {
                      'created' => reopen_date,
                      'items' => [
                          'field' => 'status',
                          'fromString' => 'Closed',
                          'toString' => 'In Progress'
                      ]
                  },
                  {
                      'created' => closed_date,
                      'items' => [
                          'field' => 'status',
                          'fromString' => 'In Progress',
                          'toString' => 'Closed'
                      ]
                  },
              ]
          }
      }
    }

    before(:each) do
      allow(issue).to receive(:attrs) {attrs}
    end

    it 'finds the number of days since this ticket was last opened for a given date' do
      expect(subject.days_since_opened(DateTime.parse(created_date) + 1)).to eq 1
      expect(subject.days_since_opened(DateTime.parse(reopen_date) + 2)).to eq 2
    end

    it 'returns nil if the issue was closed on the given date' do
      expect(subject.days_since_opened(DateTime.parse(shelved_date) + 1)).to be_nil
      expect(subject.days_since_opened(DateTime.parse(closed_date) + 1)).to be_nil
    end

    it 'returns nil if the issue was first opened after the given date' do
      expect(subject.days_since_opened(DateTime.parse(created_date) - 1)).to be_nil
    end
  end

  context '#project' do
    let(:created_date) {'2016-03-03T13:46:47.569-0700'}
    let(:changed_date) {'2016-03-10T13:46:47.569-0700'}
    let(:attrs) {
      {
          'fields' => {
              'created' => created_date,
              'project' => {'name' => 'Canvas'}
          },
          'changelog' => {
              'histories' => [
                  {
                      'created' => changed_date,
                      'items' => [
                          'field' => 'project',
                          'fromString' => 'Some Project',
                          'toString' => 'Canvas'
                      ]
                  }
              ]
          }
      }
    }

    before(:each) do
      allow(issue).to receive(:attrs) {attrs}
    end

    it 'finds the project that an issue was assigned to on a given date' do
      expect(subject.project(DateTime.parse(created_date) + 1)).to eq 'Some Project'
      expect(subject.project(DateTime.parse(changed_date) + 1)).to eq 'Canvas'
    end

    it 'returns nil if the issue had not been created before a given date' do
      expect(subject.project(DateTime.parse(created_date) - 1)).to be_nil
    end

    it 'defaults to the currently assigned project if there is no record of a project change' do
      attrs['changelog']['histories'] = []

      expect(subject.project(DateTime.parse(created_date) + 1)).to eq 'Canvas'
    end
  end

  context '#sprint_team' do
    let(:created_date) {'2016-03-03T13:46:47.569-0700'}
    let(:changed_date) {'2016-03-10T13:46:47.569-0700'}
    let(:attrs) {
      {
          'fields' => {
              'created' => created_date,
              'customfield_12700' => {'value' => 'team 2'}
          },
          'changelog' => {
              'histories' => [
                  {
                      'created' => changed_date,
                      'items' => [
                          'field' => 'Sprint Team',
                          'fromString' => 'team 1',
                          'toString' => 'team 2'
                      ]
                  }
              ]
          }
      }
    }

    before(:each) do
      allow(issue).to receive(:attrs) {attrs}
    end

    it 'finds the sprint team that an issue was assigned to on a given date' do
      expect(subject.sprint_team(DateTime.parse(created_date) + 1)).to eq 'team 1'
      expect(subject.sprint_team(DateTime.parse(changed_date) + 1)).to eq 'team 2'
    end

    it 'returns nil if the issue had not been created before a given date' do
      expect(subject.sprint_team(DateTime.parse(created_date) - 1)).to be_nil
    end

    it 'defaults to the currently assigned sprint_team if there is no record of a sprint_team change' do
      attrs['changelog']['histories'] = []

      expect(subject.sprint_team(DateTime.parse(created_date) + 1)).to eq 'team 2'
    end

    it 'returns nil if the issue has no sprint team' do
      attrs['fields']['customfield_12700'] = nil

      expect(subject.sprint_team(DateTime.parse(changed_date) + 1)).to be_nil
    end
  end
end
