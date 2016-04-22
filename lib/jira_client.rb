require 'jira'
require 'keychain'

class KeyChainError < StandardError
end

class JiraClient < JIRA::Client
  DOMAIN = 'instructure.atlassian.net'

  def inspect
    "<Jira::Client site: #{options[:site]}>"
  end

  def issues(jql, max_results: 1000, fields: nil, expand: nil)
    Enumerator.new do |y|
      count = 0
      puts "fetching issues from JQL: #{jql}"
      begin
        issues = JIRA::Resource::Issue.jql(self, jql, start_at: count, max_results: max_results, fields: fields, expand: expand)
        issues.each do |i|
          y.yield i
          count += 1
        end
        puts "fetched #{count} issues"
      end while issues.size > 0
    end
  end

  # def my_issues
  #   @my_issues ||= (
  #   my_issues_jql = "assignee = currentUser() AND resolution = Unresolved ORDER BY updatedDate DESC"
  #   issues = JIRA::Resource::Issue.jql(self, my_issues_jql)
  #   issues
  #   )
  # end

  def self.from_keychain
    @keychain_client ||= (
    keychain_item = Keychain.default.internet_passwords.where(server: DOMAIN).first
    raise KeyChainError, "#{DOMAIN} is not in your keychain" unless keychain_item
    self.from_keychain_item(keychain_item) if keychain_item
    )
  end

  def self.from_keychain_item(keychain_item)
    options = {
        :username => keychain_item.account,
        :password => keychain_item.password,
        :site     => "https://#{DOMAIN}",
        :context_path => '',
        :auth_type => :basic
    }
    self.new(options)
  end
end
