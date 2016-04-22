require 'csv'

class IssueAgeWriter
  DATE_FORMAT = '%F %T'

  def write(issues, start_date, end_date: Date.today, file: File.join(__dir__, '..', 'output', 'out.csv'))
    summary_data, sprint_teams = generate_summary_data(issues, start_date, end_date)

    sprint_teams = sprint_teams.to_a.sort

    CSV.open(file, "wb") do |csv|
      csv << %w( date count avg_age ) + sprint_teams
      summary_data.each do |k,v|
        average_age = v['count'] ? v['total_age'] / v['count'] : nil
        sprint_team_totals = sprint_teams.map {|t| (v['sprint_teams'] && v['sprint_teams'][t] && v['sprint_teams'][t]['count'] > 0) ? v['sprint_teams'][t]['total_age'] / v['sprint_teams'][t]['count'] : '' }
        csv << [k, v['count'], average_age] + sprint_team_totals
      end
    end
  end

  def generate_summary_data(issues, start_date, end_date)
    summary_data = {}
    sprint_teams = Set.new
    count = 0
    issues.each do |issue|
      puts "#{count} -  #{issue.attrs['key']}"
      count += 1
      date = start_date
      begin
        current_summary = (summary_data[date.to_s] ||= {})
        if age = issue.days_since_opened(date)
          current_summary['count'] = current_summary['count'].to_i + 1
          current_summary['total_age'] = current_summary['total_age'].to_i + age

          project = issue.project(date)
          sprint_teams.add(project)

          current_summary['sprint_teams'] ||= {}

          project_summary = (current_summary['sprint_teams'][project] ||= {})

          project_summary['count'] = project_summary['count'].to_i + 1
          project_summary['total_age'] = project_summary['total_age'].to_i + age


          team = issue.sprint_team(date)
          team = team ? "#{project} - #{team}" : "#{project} - None"
          sprint_teams.add(team)

          sprint_team_summary = (current_summary['sprint_teams'][team] ||= {})

          sprint_team_summary['count'] = sprint_team_summary['count'].to_i + 1
          sprint_team_summary['total_age'] = sprint_team_summary['total_age'].to_i + age
        end

        date = date + 1
      end while(date <= end_date)
    end
    return summary_data, sprint_teams
  end
end
