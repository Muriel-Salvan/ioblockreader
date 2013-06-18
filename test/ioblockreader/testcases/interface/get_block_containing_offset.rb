module IOBlockReaderTest

  module TestCases

    module Interface

      # Test get_block_containing_offset interface of IOBlockReader
      class GetBlockContainingOffset < ::Test::Unit::TestCase

        include IOBlockReaderTest::Common::Helpers

        def test_get_cached_block
          with('0123456789ABCDE', :block_size => 5) do |io, reader|
            assert_equal '67', reader[6..7]
            assert_equal [ [ :seek, 5 ], [ :read, 5 ] ], io.operations
            assert_equal [ '56789', 5, false ], reader.get_block_containing_offset(8)
            assert_equal [], io.operations
          end
        end

        def test_get_non_cached_block
          with('0123456789ABCDE', :block_size => 5) do |io, reader|
            assert_equal '67', reader[6..7]
            assert_equal [ [ :seek, 5 ], [ :read, 5 ] ], io.operations
            assert_equal [ '01234', 0, false ], reader.get_block_containing_offset(3)
            assert_equal [ [ :seek, 0 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_get_last_block
          with('0123456789ABCDE', :block_size => 5) do |io, reader|
            assert_equal [ 'ABCDE', 10, true ], reader.get_block_containing_offset(10)
            assert_equal [ [ :seek, 10 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_default_block
          with('0123456789ABCDE', :block_size => 5) do |io, reader|
            assert_equal [ '01234', 0, false ], reader.get_block_containing_offset
            assert_equal [ [ :seek, 0 ], [ :read, 5 ] ], io.operations
          end
        end

      end

    end

  end

end
