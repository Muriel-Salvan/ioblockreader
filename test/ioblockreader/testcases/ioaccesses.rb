module IOBlockReaderTest

  module TestCases

    # Test accesses made by IOBlockReader on the underlying IO
    class IOAccesses < ::Test::Unit::TestCase

      include IOBlockReaderTest::Common::Helpers

      def test_no_access_on_io_unless_needed
        with('0123456789') do |io, reader|
          assert_equal [], io.operations
          assert_equal '345', reader[3..5]
          assert_equal [ [ :seek, 0 ], [ :read, DEFAULT_BLOCK_SIZE ] ], io.operations
        end
      end

      def test_no_io_read_if_same_block
        with('0123456789', :block_size => 10) do |io, reader|
          assert_equal '345', reader[3..5]
          assert_equal [ [ :seek, 0 ], [ :read, 10 ] ], io.operations
          assert_equal '789', reader[7..9]
          assert_equal [], io.operations
        end
      end

      def test_no_io_read_if_a_block_is_still_in_memory
        with('0123456789', :block_size => 5, :blocks_in_memory => 2) do |io, reader|
          assert_equal '234', reader[2..4]
          assert_equal [ [ :seek, 0 ], [ :read, 5 ] ], io.operations
          assert_equal '789', reader[7..9]
          assert_equal [ [ :seek, 5 ], [ :read, 5 ] ], io.operations
          assert_equal '123', reader[1..3]
          assert_equal [], io.operations
        end
      end

      def test_io_read_replacing_oldest_block_if_needed
        with('0123456789', :block_size => 2, :blocks_in_memory => 2) do |io, reader|
          assert_equal '01', reader[0..1]
          assert_equal [ [ :seek, 0 ], [ :read, 2 ] ], io.operations
          assert_equal '23', reader[2..3]
          assert_equal [ [ :seek, 2 ], [ :read, 2 ] ], io.operations
          assert_equal '45', reader[4..5]
          assert_equal [ [ :seek, 4 ], [ :read, 2 ] ], io.operations
          assert_equal '01', reader[0..1]
          assert_equal [ [ :seek, 0 ], [ :read, 2 ] ], io.operations
        end
      end

      def test_io_read_replacing_oldest_block_and_takes_read_touch_into_account
        with('0123456789', :block_size => 2, :blocks_in_memory => 2) do |io, reader|
          assert_equal '01', reader[0..1]
          assert_equal [ [ :seek, 0 ], [ :read, 2 ] ], io.operations
          assert_equal '23', reader[2..3]
          assert_equal [ [ :seek, 2 ], [ :read, 2 ] ], io.operations
          # By re-reading '01', we touch this block which is now the most recently accessed
          assert_equal '01', reader[0..1]
          assert_equal [], io.operations
          # So accessing '45' will free '23' and not '01'
          assert_equal '45', reader[4..5]
          assert_equal [ [ :seek, 4 ], [ :read, 2 ] ], io.operations
          assert_equal '23', reader[2..3]
          assert_equal [ [ :seek, 2 ], [ :read, 2 ] ], io.operations
        end
      end

      def test_io_read_replacing_oldest_block_if_needed_not_consecutive
        with('0123456789', :block_size => 2, :blocks_in_memory => 2) do |io, reader|
          assert_equal '23', reader[2..3]
          assert_equal [ [ :seek, 2 ], [ :read, 2 ] ], io.operations
          assert_equal '01', reader[0..1]
          assert_equal [ [ :seek, 0 ], [ :read, 2 ] ], io.operations
          assert_equal '67', reader[6..7]
          assert_equal [ [ :seek, 6 ], [ :read, 2 ] ], io.operations
          assert_equal '23', reader[2..3]
          assert_equal [ [ :seek, 2 ], [ :read, 2 ] ], io.operations
        end
      end

      def test_io_read_crossing_blocks_if_needed
        with('0123456789', :block_size => 5, :blocks_in_memory => 2) do |io, reader|
          assert_equal '345', reader[3..5]
          assert_equal [ [ :seek, 0 ], [ :read, 5 ], [ :seek, 5 ], [ :read, 5 ] ], io.operations
        end
      end

      def test_io_read_crossing_more_blocks_than_allowed_in_memory_if_needed
        with('0123456789', :block_size => 2, :blocks_in_memory => 2) do |io, reader|
          assert_equal '3456', reader[3..6]
          assert_equal [ [ :seek, 2 ], [ :read, 2 ], [ :seek, 4 ], [ :read, 2 ], [ :seek, 6 ], [ :read, 2 ] ], io.operations
        end
      end

      def test_if_more_blocks_than_allowed_were_read_sweep_them_when_needed_only
        with('0123456789', :block_size => 2, :blocks_in_memory => 2) do |io, reader|
          assert_equal '3456', reader[3..6]
          assert_equal [ [ :seek, 2 ], [ :read, 2 ], [ :seek, 4 ], [ :read, 2 ], [ :seek, 6 ], [ :read, 2 ] ], io.operations
          # 23, 45 and 67 are in memory
          assert_equal '23', reader[2..3]
          assert_equal [], io.operations
          assert_equal '45', reader[4..5]
          assert_equal [], io.operations
          # By reading 89 we remove oldest accessed blocks: 67 and 23, but not 45
          assert_equal '89', reader[8..9]
          assert_equal [ [ :seek, 8 ], [ :read, 2 ] ], io.operations
          assert_equal '45', reader[4..5]
          assert_equal [], io.operations
          assert_equal '67', reader[6..7]
          assert_equal [ [ :seek, 6 ], [ :read, 2 ] ], io.operations
          assert_equal '23', reader[2..3]
          assert_equal [ [ :seek, 2 ], [ :read, 2 ] ], io.operations
        end
      end

    end

  end

end
