class Lander
  def initialize
    @pr = {}
  end

  def run
    @pr = get_pr();
    puts @pr

    # get pr id
    # get pr from github api
    # put together metadata for commit
    # do a few checks, make sure ok to land
    # figure out squashing commit, make sure final message ok
    # push commit
  end

  private

  def get_pr
    puts "Please enter PR ID:"
    pr_id = gets.strip!

    org, repo_and_id = pr_id.split('/')
    repo, id = repo_and_id.split('#')

    { org: org, repo: repo, id: id }
  end
end

Lander.new.run
