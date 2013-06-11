require 'ioblockreader/ioblockreader'

module IOBlockReader

  # Init an IOBlockReader from an existing io.
  # The io object has to be readable and seekable.
  #
  # Parameters::
  # * *io* (_IO_): The IO object
  # * *options* (<em>map<Symbol,Object></em>): Options (see IOBlockReader::IOBlockReader documentation) [default = {}]
  # Result::
  # * <em>IOBlockReader::IOBlockReader</em>: Resulting interface on the IO
  def self.init(io, options = {})
    ::IOBlockReader::IOBlockReader.new(io, options)
  end

end
