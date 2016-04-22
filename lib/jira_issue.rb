require 'date'

class JiraIssue
  def initialize(issue)
    @issue = issue
  end

  def attrs
    issue.attrs
  end

  def created_date
    @created_date ||= DateTime.parse(attrs['fields']['created'])
  end

  def open_dates
    unless @open_dates
      @open_dates = []
      @open_dates << created_date
      open_histories = attrs['changelog']['histories'].select do |h|
        h['items'].find{|i| i['field'] == "status" && i['fromString'] == 'Closed' && i['toString'] != 'Closed'}
      end

      @open_dates += open_histories.map{|h| DateTime.parse(h['created'])}
    end

    @open_dates
  end

  def last_opened_date(date)
    open_dates.select{|d| d < date}.max
  end

  def close_dates
    unless @close_dates
      close_histories = attrs['changelog']['histories'].select do |h|
        h['items'].find{|i| i['field'] == "status" && i['toString'] == 'Closed'}
      end

      @close_dates = close_histories.map{|h| DateTime.parse(h['created'])}
    end

    @close_dates
  end

  def next_closed_date(date)
    close_dates.select{|d| d > date}.min
  end

  def days_since_opened(date)
    open_date = last_opened_date(date)
    return nil unless open_date
    close_date = next_closed_date(open_date)
    (close_date == nil || close_date > date) ? (date - open_date).to_f : nil
  end

  def project_transitions
    unless @project_transitions
      project_histories = attrs['changelog']['histories'].select do |h|
        h['items'].find{|i| i['field'] == "project"}
      end

      @project_transitions = {}

      project_histories.each do |h|
        @project_transitions[DateTime.parse(h['created'])] = h['items'].find{|i| i['field'] == 'project'}['fromString']
      end
    end

    @project_transitions
  end

  def project(date)
    return nil if created_date > date

    next_transition_date = project_transitions.keys.select {|d| d > date}.min
    return next_transition_date ? project_transitions[next_transition_date] : attrs['fields']['project']['name']
  end
  
  def sprint_team_transitions
    unless @sprint_team_transitions
      sprint_team_histories = attrs['changelog']['histories'].select do |h|
        h['items'].find{|i| i['field'] == "Sprint Team"}
      end

      @sprint_team_transitions = {}
      sprint_team_histories.each do |h|
        @sprint_team_transitions[DateTime.parse(h['created'])] = h['items'].find{|i| i['field'] == 'Sprint Team'}['fromString']
      end
    end

    @sprint_team_transitions
  end

  def sprint_team(date)
    return nil if created_date > date

    next_transition_date = sprint_team_transitions.keys.select {|d| d > date}.min

    return next_transition_date ? sprint_team_transitions[next_transition_date] : (attrs['fields']['customfield_12700'] || {})['value']
  end

  private

  def issue
    @issue
  end

end
