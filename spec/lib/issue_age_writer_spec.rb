require_relative '../../lib/issue_age_writer'

RSpec.describe IssueAgeWriter do
  context '#generate_summary_data' do
    let(:start_date) {DateTime.parse('2015-01-01')}
    let(:issue) {
      double('issue',
             attrs: {'key' => 'issue1'},
             days_since_opened: 12,
             project: 'Project',
             sprint_team: 'Team')
    }
    let(:issue_on_different_project) {
      double('issue',
             attrs: {'key' => 'issue2'},
             days_since_opened: 6,
             project: 'Other Project',
             sprint_team: 'Team')
    }

    let(:issue_on_different_team) {
      double('issue',
             attrs: {'key' => 'issue3'},
             days_since_opened: 20,
             project: 'Project',
             sprint_team: 'Other Team')
    }

    let(:issue_with_no_sprint_team) {
      double('issue',
             attrs: {'key' => 'issue4'},
             days_since_opened: 20,
             project: 'Project',
             sprint_team: nil)
    }

    let(:inactive_issue) {
      double('issue',
             attrs: {'key' => 'issue5'},
             days_since_opened: nil,
             project: 'Project',
             sprint_team: 'Team')
    }

    context 'generates summary data' do
      it 'for overall totals' do
        issues = [issue, issue_on_different_project]
        summary_data, sprint_teams = subject.generate_summary_data(issues, start_date, start_date)

        expect(summary_data.size).to eq 1
        date_data = summary_data[start_date.to_s]

        expect(date_data['count']).to eq 2
        expect(date_data['total_age']).to eq 18
      end

      it 'for project totals' do
        issues = [issue, issue_on_different_project, issue_on_different_team]
        summary_data, sprint_teams = subject.generate_summary_data(issues, start_date, start_date)

        expect(summary_data.size).to eq 1
        project_data = summary_data[start_date.to_s]['sprint_teams']

        expect(project_data.size).to eq 5
        expect(project_data['Project']['count']).to eq 2
        expect(project_data['Project']['total_age']).to eq 32

        expect(project_data['Project - Team']['count']).to eq 1
        expect(project_data['Project - Team']['total_age']).to eq 12

        expect(project_data['Project - Other Team']['count']).to eq 1
        expect(project_data['Project - Other Team']['total_age']).to eq 20

        expect(project_data['Other Project']['count']).to eq 1
        expect(project_data['Other Project']['total_age']).to eq 6

        expect(project_data['Other Project - Team']['count']).to eq 1
        expect(project_data['Other Project - Team']['total_age']).to eq 6
      end

      it 'for several dates' do
        end_date = start_date + 1
        issues = [issue, issue_on_different_project]
        summary_data, sprint_teams = subject.generate_summary_data(issues, start_date, end_date)

        expect(summary_data.size).to eq 2
        expect(summary_data.keys).to include(start_date.to_s, end_date.to_s)
      end

      it 'excluding inactive issues' do
        issues = [issue, inactive_issue]
        summary_data, sprint_teams = subject.generate_summary_data(issues, start_date, start_date)

        expect(summary_data.size).to eq 1

        date_data = summary_data[start_date.to_s]

        expect(date_data['count']).to eq 1
        expect(date_data['total_age']).to eq 12
      end
    end

    context 'generates sprint team info' do
      it 'for both project and team/project combinations' do
        summary_data, sprint_teams = subject.generate_summary_data([issue], start_date, start_date)

        expect(sprint_teams.size).to eq 2
        expect(sprint_teams).to include("Project - Team")
        expect(sprint_teams).to include("Project")
      end

      it 'for issues where sprint team is nil' do
        issues = [issue_with_no_sprint_team]
        summary_data, sprint_teams = subject.generate_summary_data(issues, start_date, start_date)

        expect(sprint_teams.size).to eq 2
        expect(sprint_teams).to include("Project - None")
        expect(sprint_teams).to include("Project")
      end

      it 'without duplicate entries' do
        issues = [issue, issue]
        summary_data, sprint_teams = subject.generate_summary_data(issues, start_date, start_date)

        expect(sprint_teams.size).to eq 2
        expect(sprint_teams).to include("Project - Team")
        expect(sprint_teams).to include("Project")
      end
    end
  end
end