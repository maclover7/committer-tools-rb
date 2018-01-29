require 'json'
require 'rest-client'

class HTTPHelper
  class << self
    attr_writer :token
  end

  def self.get(url)
    RestClient.get(url, { params: { access_token: @token } }).body
  end

  def self.get_json(url)
    JSON.parse(get(url))
  end
end

class Lander
  def run(github_pr, metadata)
    check_to_land(github_pr, metadata)
    introduce_commit(github_pr, metadata)

    puts "[\u{2714}] Commit(s) applied locally. Please update to your liking, and then type 'lgtm'."

    if ENV['BOT'] && ENV['BOT'] == 'bot'
      lgtm = "lgtm"
    else
      lgtm = gets.strip!

      while !lgtm do
        sleep
      end
    end

    if lgtm && lgtm == 'lgtm'
      add_metadata_to_commit(metadata)
      validate_commit

      puts "\n[\u{2714}] Landed in #{`git rev-list upstream/master...HEAD`} -- committer-tools is done! Edit away to your content, and then push away :)"
    end
  end

  private

  def add_metadata_to_commit(metadata)
    msg = `git log --format=%B -n 1` + [metadata[:pr_url], metadata[:reviewers]].compact.join("\n")
    `git commit --amend -m '#{msg}'`
  end

  def check_to_land(github_pr, metadata)
    # At least 48 hours of review time
    if Time.parse(github_pr['created_at']) > (Date.today - 2).to_time
      puts "[✘] PR must remain open for at least 48 hours"
    end

    # At least two approvals
    if (metadata[:reviewers].length < 2)
      puts "[✘] PR must have at least two reviewers"
    end

    # No failing CI builds
    failing_statuses = metadata[:ci_statuses].select { |job| job[:status] == 'failure' }
    if (failing_statuses.length > 0)
      puts "[✘] Failing builds on #{failing_statuses.map { |s| s[:name] }.join(', ')}"
    end
  end

  def introduce_commit(github_pr, metadata)
    # Clear current status
    `git am --abort`
    `git rebase --abort`
    `git checkout master`

    # Update from upstream
    `git fetch upstream`
    `git merge --ff-only upstream/master`

    # Download and apply patch
    `curl -L https://github.com/#{github_pr['base']['user']['login']}/#{github_pr['base']['repo']['name']}/pull/#{github_pr['number']}.patch | git am --whitespace=fix`
  end

  def validate_commit
    puts "Running core-validate-commit..."
    system('git rev-list upstream/master...HEAD | xargs core-validate-commit')
  end
end

class MetadataCollector
  NODE_README_URL = 'https://raw.githubusercontent.com/nodejs/node/master/README.md'
  REVIEWER_REGEX = /\* \[(.+?)\]\(.+?\) -\s\*\*(.+?)\*\* &lt;(.+?)&gt;/m

  def collect(github_pr)
    {
      pr_url: collect_pr_url(github_pr),
      reviewers: collect_reviewers(github_pr),
      ci_statuses: collect_ci_statuses(github_pr)
    }
  end

  private

  def collect_ci_statuses(github_pr)
    HTTPHelper.get_json(github_pr['statuses_url']).map do |status|
      { name: status['context'], status: status['state'] }
    end
  end

  def collect_pr_url(github_pr)
    "PR-URL: #{github_pr['html_url']}"
  end

  def collect_reviewers(github_pr)
    # Collect a list of all possible reviewers
    possible_reviewers = {}
    readme = HTTPHelper.get(NODE_README_URL)

    # GitHub being stupid...
    # Treat every two lines as one...
    readme.split("\n").unshift('').each_slice(2).to_a.each do |a, b|
      if (m = REVIEWER_REGEX.match("#{a} #{b}"))
        possible_reviewers[m[1]] = {
          name: m[2],
          email: m[3]
        }
      end
    end

    # Use this list to identify reviewers for the current PR!
    reviewer_usernames = HTTPHelper.get_json("#{github_pr['url']}/reviews").map do |review|
      next unless review['state'] == 'APPROVED'
      review['user']['login']
    end.compact.uniq

    reviewer_usernames.map do |reviewer_username|
      user = possible_reviewers[reviewer_username]
      next unless user

      "Reviewed-By: #{user[:name]} <#{user[:email]}>"
    end.compact
  end
end

class Preparer
  AUTH_FILE = '.ctconfig'

  def run
    HTTPHelper.token = get_auth()
    pr = get_pr()
    get_github_pr(pr)
  end

  private

  def get_auth
    begin
      auth = File.read("#{ENV['HOME']}/#{AUTH_FILE}")
      JSON.parse(auth)['token']
    rescue
      raise "Unable to load authentication information"
    end
  end

  def get_github_pr(pr)
    HTTPHelper.get_json(
      "https://api.github.com/repos/#{pr[:org]}/#{pr[:repo]}/pulls/#{pr[:id]}"
    )
  end

  def get_pr
    if ENV['BOT'] && ENV['BOT'] == 'bot'
      pr_id = ENV['COMMITTER_TOOLS_PR_ID']
    else
      puts "Please enter PR ID:"
      pr_id = gets.strip!
    end

    begin
      org, repo_and_id = pr_id.split('/')
      repo, id = repo_and_id.split('#')
      { org: org, repo: repo, id: id }
    rescue
      raise "Invalid PR ID: #{pr_id}"
    end
  end
end

class LandCommand
  def run(github_pr)
    metadata = MetadataCollector.new.collect(github_pr)
    Lander.new.run(github_pr, metadata)
  end
end
