require 'csv'

class IssueWriter
  DATE_FORMAT = '%F %T'
  FIELDS = {
      key:
          ->(attrs) {attrs['key']},
      issue_type:
          ->(attrs) {attrs['fields']['issuetype']['name']},
      status:
          ->(attrs) {attrs['fields']['status']['name']},
      sprint_team:
          ->(attrs) {attrs['fields']['customfield_12700']['value']},
      created:
          ->(attrs) {DateTime.parse(attrs['fields']['created']).strftime(DATE_FORMAT)},
      reopen_date:
          ->(attrs) {DateTime.parse(attrs['fields']['customfield_13402']).strftime(DATE_FORMAT)},
      resolution_date:
          ->(attrs) {DateTime.parse(attrs['fields']['resolutiondate']).strftime(DATE_FORMAT)},
      components:
          ->(attrs) {attrs['fields']['components'].map{|c| c['name']}.join(',')},
  }

  def write(issues, fields, file)
    CSV.open(file, "wb") do |csv|
      csv << fields
      issues.each {|issue| csv << filter_issue(issue.attrs, fields)}
    end
  end

  def filter_issue(attrs, fields)
    fields.map do |f|
      begin
        FIELDS[f].call(attrs)
      rescue NoMethodError, TypeError
        nil
      end
    end
  end

  def write_common_fields(issues, file = File.join(__dir__, '..', 'output', 'out.csv'))
    write(issues, FIELDS.keys, file)
  end
end
