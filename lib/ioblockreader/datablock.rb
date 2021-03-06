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
    #
    # Parameters::
    # * *io* (_IO_): IO to read from
    def initialize(io)
      @io = io
      @offset = nil
      @last_access_time = nil
      @data = ''
      @data.force_encoding(@io.external_encoding) if (@data.respond_to?(:force_encoding))
    end

    # Fill the data block for a given IO
    #
    # Parameters::
    # * *offset* (_Fixnum_): Offset of this block in the IO
    # * *size* (_Fixnum_): Size of the block to be read
    def fill(offset, size)
      @offset = offset
      @last_access_time = @@access_time_sequence
      @@access_time_sequence += 1
      #puts "[IOBlockReader] - Read #{size} bytes @#{@offset} in datablock ##{self.object_id}"
      @io.seek(@offset)
      @io.read(size, @data)
      #puts "[IOBlockReader] - Data read: #{@data.inspect}"
      @last_block = @io.eof?
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

    # Get a string representation of this block.
    # This is mainly used for debugging purposes.
    #
    # Result::
    # * _String_: String representation
    def to_s
      return "[##{self.object_id}: @#{@offset} (last access: #{@last_access_time})#{@last_block ? ' (last block)' : ''}]"
    end

  end

end
