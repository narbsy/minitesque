require 'resque'
require 'lib/models'
require 'minitest/unit'
require 'lib/core_ext'

module Job
  @queue = :default

  # Creates a result and prints errors if it is unable to be saved, returning
  # it regardless. Should probably throw an exception
  def self.check_result(hash)
    returning(Result.new hash) do |r|
      unless r.save
        # error checking..
        puts "Oh noes! It didn't save!"
        r.errors.each { |e| puts e }
      end

      puts r.inspect if @debug
    end
  end

  def self.perform(params)
    start = Time.now
    puts params
    @debug = params["development"]
    puts "running test whatevers" if @debug
    puts "in development" if @debug

    sub = Submission.get(params["id"])

    # load the code wrapped in a begin block so that we can catch all of the
    # exceptions
    begin
      # Use an anonymous module to namespace the loaded classes.
      mod = Module.new do
        module_eval sub.code, sub.filename
        # Load our test files. We probably want to limit this to the test suite
        # for the current project i.e. fibfact, chess rating, etc.
        module_eval File.read('test/fibfact_test.rb')
      end
    rescue Exception => e
      # Use a predetermined test name for the current project to denote errors
      # that we got on loading the file.
      test = Test.first_or_create :name => "on-load", :suite => sub.name
      check_result  :test => test, :submission => sub, 
                    :result => "E", :report => e.message

      puts "saving submission"
      sub.score = 0
      sub.save
    end
    puts "Didn't error..."

    # Grab our test harness.
    mini_test = MiniTest::Unit.new
    test_suites = MiniTest::Unit::TestCase.test_suites

    if @debug
      puts test_suites
      puts test_suites.map { |e| e.test_methods.join(", ") }
    end

    test_suites.each do |suite|
      puts "Running suite #{ suite }" if @debug

      suite.test_methods.each do |test|
        puts "Running test #{ test }" if @debug

        # Lets capture stdout from MiniTest::Unit.
        stdout = StringIO.new
        MiniTest::Unit.output = stdout

        # Run just the current test; 
        # TODO should probably add ^ and $ so it REALLY 
        # only runs the current test in the face of overlapping names
        tests, assertions = mini_test.run_test_suites Regexp.new(test)

        # Make sure we ignore the anonymous module's mark on the suite's
        # classname, and allow for multiple levels of nesting.
        clean_suite_name = suite.name.split(/::/).drop(1).join
        # Tests had better be unique by name...
        test = returning( Test.first_or_new :name => test, :suite => clean_suite_name ) do |t|
          t.assertions = assertions if t.new? || t.assertions < assertions
          t.save
        end

        check_result  :test => test, :submission => sub, 
                      :result => stdout.string, :report => mini_test.report

        failures, errors = mini_test.failures, mini_test.errors
        puts [tests, assertions, failures, errors].join("\t") if @debug
      end
    end

    sub.score = 100
    sub.save

    total_time = Time.now - start
    puts "Took: #{ total_time }" if @debug
  end
end

