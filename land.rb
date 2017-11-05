require 'json'
require 'rest-client'

class Lander
  def initialize
    @pr = {}
    @github_pr = {}
  end

  def run
    @pr = get_pr()
    @github_pr = get_github_pr(@pr)

    # get pr id
    # get pr from github api
    # put together metadata for commit
    # do a few checks, make sure ok to land
    # figure out squashing commit, make sure final message ok
    # push commit
  end

  private

  def get_github_pr(pr)
    JSON.parse(
      RestClient.get(
        "https://api.github.com/repos/#{pr[:org]}/#{pr[:repo]}/pulls/#{pr[:id]}"
      )
    )
  end

  def get_pr
    puts "Please enter PR ID:"
    pr_id = gets.strip!

    org, repo_and_id = pr_id.split('/')
    repo, id = repo_and_id.split('#')

    { org: org, repo: repo, id: id }
  end
end

Lander.new.run
