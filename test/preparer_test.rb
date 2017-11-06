require "test_helper"

class PreparerTest < Minitest::Test
  def setup
    @preparer = Preparer.new
  end

  def test_get_pr_invalid
    @preparer.stub(:gets, "blahblah\n") do
      error = assert_raises { @preparer.send(:get_pr) }
      assert_equal("Invalid PR ID: blahblah", error.message)
    end
  end

  def test_get_pr_valid
    @preparer.stub(:gets, "nodejs/build#973\n") do
      assert_equal({ org: 'nodejs', repo: 'build', id: '973' },
                   @preparer.send(:get_pr))
    end
  end
end
