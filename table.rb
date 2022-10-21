class Table
  attr_reader :headers, :data, :meta_data

  def initialize(headers, data)
    @headers = sanitize(headers)
    @data = data.map(&method(:sanitize))

    raise ArgumentError unless TableValidator.valid?(self)
  end

  private

  def sanitize(data)
    data.map do |d|
      d.to_s.capitalize
    end
  end
end

class TableValidator

  def initialize(table)
    raise ArgumentError unless table.is_a?(Table)

    @headers = table.headers
    @data = table.data
  end

  def self.valid?(table)
    new(table).valid?
  end

  def valid?
    valid_data?             &&
      valid_headers?        &&
      data_header_match?
  end

  private

  def valid_data?
    @data.is_a?(Array) &&
      !@data.empty?    &&
      consistent_data?
  end

  def consistent_data?
    @data.map(&:length).uniq.length.eql?(1) &&
      @data.first.all?(String)
  end

  def valid_headers?
    @headers.is_a?(Array) && @headers.all?(String)
  end

  def data_header_match?
    @data.first.length.eql?(@headers.length)
  end
end

class TableEvaluator

  def initialize(table)
    raise ArgumentError unless table.is_a?(Table)

    @headers = table.headers
    @data = table.data

    @column_count = @headers.length
    @row_count = @data.length
    @max_column_lengths = max_column_lengths
    @total_row_length = total_row_length
  end

  def self.evaluate(table)
    new(table).evaluate
  end

  def evaluate
    {
      'column_count': @column_count,
      'row_count': @row_count,
      'max_column_lengths': @max_column_lengths,
      'total_row_length': @total_row_length
    }
  end

  private

  def max_column_lengths
    (0...@column_count).map do |column_index|
      ([@headers] + @data).map do |row|
        row[column_index].length
      end.max
    end
  end

  def total_row_length
    @max_column_lengths.inject(:+)
  end
end

class TablePrinter

  DEFAULT_MESSAGE = 'Printing table...'.freeze
  DEFAULT_DELIMITER = ' | '.freeze

  def initialize(table, message = DEFAULT_MESSAGE, delimiter = DEFAULT_DELIMITER)
    raise ArgumentError unless table.is_a?(Table)

    @headers = table.headers
    @data = table.data
    @message = message
    @delimiter = delimiter

    @meta_data = TableEvaluator.evaluate(table)
  end

  def self.print(table, message = DEFAULT_MESSAGE, delimiter = DEFAULT_DELIMITER)
    new(table, message, delimiter).print
  end

  def print
    puts
    puts message_string
    puts
    puts header_string + "\n" + separator_string
    puts data_string
  end

  private

  def message_string(adjust = :ljust)
    @message.send(adjust, total_row_length)
  end

  def separator_string(chararacter = '-')
    chararacter * @meta_data[:total_row_length]
  end

  def header_string
    row_string(@headers, :center).join(@delimiter)
  end

  def data_string
    @data.map do |row|
      row_string(row).join(@delimiter)
    end.join("\n")
  end

  def row_string(row, adjust = :ljust)
    row.each_with_index.map do |cell, index|
      cell.send(adjust, column_length(index))
    end
  end

  def column_length(column_index)
    @meta_data[:max_column_lengths][column_index]
  end

  def total_row_length
    @meta_data[:total_row_length]
  end
end
