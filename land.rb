require 'json'
require 'rest-client'

class Lander
  class MetadataCollector
    NODE_README_URL = 'https://raw.githubusercontent.com/nodejs/node/master/README.md'
    REVIEWER_REGEX = /\* \[(.+?)\]\(.+?\) -\s\*\*(.+?)\*\* &lt;(.+?)&gt;/m

    def initialize(github_pr)
      @github_pr = github_pr
    end

    def collect
      {
        pr_url: collect_pr_url,
        reviewers: collect_reviewers,
        ci_statuses: collect_ci_statuses
      }
    end

    private

    def collect_ci_statuses
      JSON.parse(
        RestClient.get(
          @github_pr['statuses_url'],
          { params: { access_token: ENV['GH_TOKEN'] } }
        )
      ).map do |status|
        { name: status['context'], status: status['state'] }
      end
    end

    def collect_pr_url
      "PR-URL: #{@github_pr['html_url']}"
    end

    def collect_reviewers
      # Collect a list of all possible reviewers
      possible_reviewers = {}
      readme = RestClient.get(NODE_README_URL, { params: { access_token: ENV['GH_TOKEN'] } }).body

      # GitHub being stupid...
      # Treat every two lines as one...
      readme.split("\n").each_slice(2).to_a.each do |a, b|
        if (m = REVIEWER_REGEX.match("#{a} #{b}"))
          possible_reviewers[m[1]] = {
            name: m[2],
            email: m[3]
          }
        end
      end

      # Use this list to identify reviewers for the current PR!
      reviewer_usernames = JSON.parse(RestClient.get("#{@github_pr['url']}/reviews", { params: { access_token: ENV['GH_TOKEN'] } })).map do |review|
        next unless review['state'] == 'APPROVED'
        review['user']['login']
      end.compact.uniq

      reviewer_usernames.map do |reviewer_username|
        user = possible_reviewers[reviewer_username]

        "Reviewed-By: #{user[:name]} <#{user[:email]}>"
      end
    end
  end

  def initialize
    @pr = { org: 'nodejs', repo: 'node', id: '14998' }
    @github_pr = {}
    @metadata = {}
  end

  def run
    @pr = get_pr()
    @github_pr = get_github_pr(@pr)
    @metadata = get_metadata(@github_pr)
    check_to_land(@github_pr, @metadata)
    introduce_commit(@pr, @metadata)
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

  def get_github_pr(pr)
    JSON.parse(
      RestClient.get(
        "https://api.github.com/repos/#{pr[:org]}/#{pr[:repo]}/pulls/#{pr[:id]}",
        { params: { access_token: ENV['GH_TOKEN'] } }
      )
    )
  end

  def get_metadata(github_pr)
    MetadataCollector.new(github_pr).collect
  end

  def get_pr
    puts "Please enter PR ID:"
    pr_id = gets.strip!

    org, repo_and_id = pr_id.split('/')
    repo, id = repo_and_id.split('#')

    { org: org, repo: repo, id: id }
  end

  def introduce_commit(pr, metadata)
    # Clear current status
    `git am --abort`
    `git rebase --abort`
    `git checkout master`

    # Update from upstream
    `git fetch upstream`
    `git merge --ff-only upstream/master`

    # Download and apply patch
    `curl -L https://github.com/#{pr[:org]}/#{pr[:repo]}/pull/#{pr[:id]}.patch | git am --whitespace=fix`

    puts "[\u{2714}] Commit(s) applied locally. Please update to your liking, and then type 'continue'."
    continue = gets.strip!

    while !continue do
      sleep
    end

    if continue && continue == 'continue'
      add_metadata_to_commit(metadata)
      validate_commit
    end
  end

  def validate_commit
    puts "Running core-validate-commit..."
    exec('git rev-list upstream/master...HEAD | xargs core-validate-commit')
  end
end

###
# What this tool does:
###
# * get pr id
# * get pr from github api
# * put together metadata for commit
# * do a few checks, make sure ok to land
# * figure out squashing commit, make sure final message ok
##
# What you have to do:
##
# * push commit

Lander.new.run
