module IOBlockReader

  # Class defining a data block
  class DataBlock

    # Use a Fixnum sequence instead of real Time values for last_access_time for performance reasons
    @@access_time_sequence = 0

    # Offset of this block, in bytes
    #  _Fixnum_
    attr_reader :offset

    # Timestamp indicating when this block has been touched (created or done with touch method)
    #  _Fixnum_
    attr_reader :last_access_time

    # Data contained in this block
    #  _String_
    attr_reader :data

    # Constructor
    def initialize
      @offset = nil
      @last_access_time = nil
      @data = ''.force_encoding('ASCII-8BIT')
    end

    # Fill the data block for a given IO
    #
    # Parameters::
    # * *io* (_IO_): IO to read from
    # * *offset* (_Fixnum_): Offset of this block in the IO
    # * *size* (_Fixnum_): Size of the block to be read
    def fill(io, offset, size)
      @offset = offset
      @last_access_time = @@access_time_sequence
      @@access_time_sequence += 1
      #puts "[IOBlockReader] - Read #{size} @#{@offset}"
      io.seek(@offset)
      io.read(size, @data)
      @last_block = io.eof?
    end

    # Is this block the last of its IO stream?
    #
    # Result:
    # * _Boolean_: Is this block the last of its IO stream?
    def last_block?
      return @last_block
    end

    # Update the last access time
    def touch
      @last_access_time = @@access_time_sequence
      @@access_time_sequence += 1
    end

  end

end
