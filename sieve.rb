require 'optparse'
require_relative 'table'

class SieveOfEratosthenes
  attr_reader :ubound, :int_list, :run_time

  def initialize(ubound)
    @ubound = ubound
    @int_list = Array.new(ubound, true)
    @run_time = nil
  end

  def run
    start = Time.now

    (2..Math.sqrt(int_list.size)).each do |i|
      Thread.new { filter_composites(i) }.join if int_list[i]
    end

    @run_time = Time.now - start
  end

  private

  def filter_composites(base)
    (base**2..int_list.size).step(base) do |i|
      int_list[i] = false
    end
  end
end

class SieveTester
  attr_reader :ubounds, :sieves, :results

  def initialize(ubounds)
    @ubounds = ubounds.sort
    @sieves = create_sieves
    @run_complete = false
    @running = false
    @results = []
  end

  def run
    @running = true

    sieves.each(&:run)
    collect_results

    @run_complete = true
    @running = false
  end

  def print_results
    wait_for_run unless @run_complete

    TablePrinter.print(Table.new(['Upper Bound', 'Run Time (seconds)'], results),
                       "Ran #{sieves.length} sieves...")
  end

  private

  def create_sieves
    ubounds.map do |ubound|
      SieveOfEratosthenes.new(ubound)
    end
  end

  def collect_results
    sieves.each do |sieve|
      results << [sieve.ubound.to_s, sieve.run_time.to_s]
    end
  end

  def wait_for_run
    sleep(0.1) until @run_complete
  end
end

if $PROGRAM_NAME == __FILE__

  options = {}
  OptionParser.new do |parser|
    parser.banner = 'Usage: sieve.rb [options]'

    parser.on_tail('-h', '--help', 'Show this message.') do
      puts parser
      exit
    end

    parser.on('-u', '--ubounds UBOUND[,UBOUND]', Array, 'Upper bounds.') do |ub|
      options[:ubounds] = ub.map(&:to_i).reject(&:zero?).uniq
    end
  end.parse!

  raise OptionParser::MissingArgument if options[:ubounds].nil?
  raise OptionParser::InvalidArgument if options[:ubounds].empty?

  tester = SieveTester.new(options[:ubounds])
  tester.run
  tester.print_results
end
