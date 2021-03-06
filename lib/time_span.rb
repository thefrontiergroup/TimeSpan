require 'delegate'
require 'time_span_serializer'

class TimeSpan < DelegateClass(Numeric)
  VERSION = "1.1.1"

  SECONDS_PER_MINUTE = 60.0
  SECONDS_PER_HOUR = 3600.0

  SECONDS_SERIALIZER = TimeSpanSerializer.new(:seconds)

  # interface used by libs like ActiveRecord to convert instances of TimeSpan to a string.
  def self.dump(value)
    SECONDS_SERIALIZER.dump(value)
  end

  # interface used by libs like ActiveRecord to convert strings to instances of TimeSpan.
  # this is designed to be flexible in input type. So it can be as a
  # generic "Create me a TimeSpan from this thing" method
  def self.load(value)
    SECONDS_SERIALIZER.load(value)
  end

  def self.from_seconds(seconds)
    new(seconds, :seconds)
  end

  def self.from_minutes(minutes)
    new(minutes, :minutes)
  end

  def self.from_hours(hours)
    new(hours, :hours)
  end

  # create a new TimeSpan with the specified
  def self.new(value, unit=:seconds)
    raise ArgumentError, "Value cannot be nil" if value.nil?
    case unit
    when :seconds
      super(value)
    when :minutes
      super(value*SECONDS_PER_MINUTE)
    when :hours
      super(value*SECONDS_PER_HOUR)
    end
  end

  # return a new TimeSpan from a string
  def self.parse(value, unit=:seconds)
    raise ArgumentError, "Value cannot be nil" if value.nil?
    new(value.to_f, unit)
  end

  def total_seconds
    self.to_f
  end

  def total_minutes
    self.to_f / SECONDS_PER_MINUTE
  end

  def total_hours
    self.to_f / SECONDS_PER_HOUR
  end

  def hours
    total_seconds.to_i / SECONDS_PER_HOUR.to_i
  end

  def minutes
    (total_seconds.to_i / SECONDS_PER_MINUTE.to_i) % SECONDS_PER_MINUTE.to_i
  end

  def seconds
    total_seconds % SECONDS_PER_MINUTE.to_i
  end

  def format(format)
    result = format.dup
    result.gsub!("%h", hours.to_s)
    result.gsub!("%m", minutes.to_s)
    result.gsub!("%s", seconds.to_s)
    result
  end

  # returns a string in the format of
  #    05:13  (5 Minutes 13 Seconds)
  #  3:01:29  (3 Hours, 1 Minute, 29 Seconds)
  def pretty
    components = minutes, seconds

    if hours > 0
      hours_string = hours.to_s << ":"
    else
      hours_string = ""
    end

    component_string = components
    .compact
    .map { |value| "%02i" % value }
    .join(":")

    hours_string << component_string
  end

# Overrides - Numeric

  def +(other)
    other = new(other) # make sure other is a TimeSpan
    new(self.total_seconds + other.total_seconds)
  end

  def -(other)
    other = new(other) # make sure other is a TimeSpan
    new(self.total_seconds - other.total_seconds)
  end

  def /(other)
    other = new(other) # make sure other is a TimeSpan
    new(self.total_seconds / other.total_seconds)
  end

  def *(other)
    other = new(other) # make sure other is a TimeSpan
    new(self.total_seconds * other.total_seconds)
  end

# Overrides - Object

  def to_s
    pretty
  end

  def inspect
    pretty
  end

  private

  def new(value)
    self.class.load(value)
  end
end
