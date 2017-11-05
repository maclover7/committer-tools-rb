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
      return_val = ""

      # PR-URL
      return_val += collect_pr_url

      # Reviewers
      return_val += collect_reviewers

      return_val
    end

    private

    def collect_pr_url
      "PR-URL: #{@github_pr['html_url']}\n"
    end

    def collect_reviewers
      # Collect a list of all possible reviewers
      possible_reviewers = {}
      readme = RestClient.get(NODE_README_URL).body

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
      reviewer_usernames = JSON.parse(RestClient.get("#{@github_pr['url']}/reviews")).map do |review|
        next unless review['state'] == 'APPROVED'
        review['user']['login']
      end.compact.uniq

      reviewer_usernames.map do |reviewer_username|
        user = possible_reviewers[reviewer_username]

        "Reviewed-By: #{user[:name]} <#{user[:email]}>"
      end.join("\n")
    end
  end

  def initialize
    @pr = { org: 'nodejs', repo: 'node', id: '14998' }
    @github_pr = {}
    @metadata = ''
  end

  def run
    @pr = get_pr()
    @github_pr = get_github_pr(@pr)
    @metadata = get_metadata(@github_pr)
  end

  private

  def get_github_pr(pr)
    JSON.parse(
      RestClient.get(
        "https://api.github.com/repos/#{pr[:org]}/#{pr[:repo]}/pulls/#{pr[:id]}"
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
