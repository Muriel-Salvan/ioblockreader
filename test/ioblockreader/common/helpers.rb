require 'stringio'

module IOBlockReaderTest

  module Common

    module Helpers

      DEFAULT_BLOCK_SIZE = 268435456

      def with(string, reader_options = {})
        test_io = IOBlockReaderTest::Common::TestIO.new(string)
        reader = IOBlockReader.init(test_io, reader_options)
        yield(test_io, reader)
      end

    end

  end

end
