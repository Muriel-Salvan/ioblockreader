module IOBlockReaderTest

  module TestCases

    module Interface

      # Test common interface of IOBlockReader
      class Common < ::Test::Unit::TestCase

        include IOBlockReaderTest::Common::Helpers

        def test_init_from_an_IO
          test_io = IOBlockReaderTest::Common::TestIO.new('0123456789')
          reader = IOBlockReader.init(test_io)
          assert_not_nil reader
          assert_equal '345', reader[3..5]
        end

        def test_option_block_size
          with('0123456789', :block_size => 2) do |io, reader|
            assert_equal '012', reader[0..2]
            assert_equal [ [ :seek, 0 ], [ :read, 2 ], [ :seek, 2 ], [ :read, 2 ] ], io.operations
          end
        end

        def test_option_blocks_in_memory
          with('0123456789', :block_size => 2, :blocks_in_memory => 3) do |io, reader|
            assert_equal '0123', reader[0..3]
            assert_equal [ [ :seek, 0 ], [ :read, 2 ], [ :seek, 2 ], [ :read, 2 ] ], io.operations
            assert_equal '45', reader[4..5]
            assert_equal [ [ :seek, 4 ], [ :read, 2 ] ], io.operations
            # Re-accessing '01' won't read from the IO
            assert_equal '01', reader[0..1]
            assert_equal [], io.operations
          end
        end

      end

    end

  end

end
