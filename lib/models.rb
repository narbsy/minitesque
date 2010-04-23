require 'datamapper'

DataMapper.setup(:default, 'sqlite3:development.db')

class Submission
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :score, Integer
  property :filename, String
  
  property :code, Text

  has n, :results
  has n, :tests, :through => :results
end

class Test
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :suite, String
  property :assertions, Integer

  has n, :results
  has n, :submissions, :through => :results
end

class Result
  include DataMapper::Resource

  property :result, String, :length => 1
  property :report, Text
  property :submission_id, Integer, :key => true
  property :test_id, Integer, :key => true

  belongs_to :submission
  belongs_to :test

  def passed?
    result == "."
  end

  def failed?
    result == "F"
  end

  def errored?
    result == "E"
  end
end

=begin
class DelayedJob
  include DataMapper::Resource

  property :id, Serial
  property :priority, Integer, :default => 0
  property :attemps, Integer, :default => 0
  property :handler, Text
  property :last_error, String
  property :run_at, DateTime
  property :locked_at, DateTime
  property :failed_at, DateTime
  property :locked_by, String
end

class ScoreAssignment < Struct.new(:id)
  def perform
    a = Assignment.get(id)
    a.score = 100
    a.save
  end
end

  before i forget,

  m = MiniTest::Unit.new
  m.run_test_suites /./ or some such.
  m.failures, errors, skips, test_count, assertion_count
=end

DataMapper.auto_upgrade!
