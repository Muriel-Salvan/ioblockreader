module IOBlockReaderTest

  module TestCases

    module Interface

      # Test index interface of IOBlockReader
      class Index < ::Test::Unit::TestCase

        include IOBlockReaderTest::Common::Helpers

        def test_index_string_first_block
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal 3, reader.index('34')
            assert_equal [ [ :seek, 0 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_string_other_block
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal 5, reader.index('56')
            assert_equal [ [ :seek, 0 ], [ :read, 5 ], [ :seek, 5 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_string_cross_block
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal 4, reader.index('45')
            assert_equal [ [ :seek, 0 ], [ :read, 5 ], [ :seek, 5 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_string_none
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal nil, reader.index('46')
            assert_equal [ [ :seek, 0 ], [ :read, 5 ], [ :seek, 5 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_string_with_offset
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal 5, reader.index('56', 5)
            assert_equal [ [ :seek, 5 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_string_none_with_offset
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal nil, reader.index('45', 5)
            assert_equal [ [ :seek, 5 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_regexp_first_block
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal 3, reader.index(/3\d/, 0, 2)
            assert_equal [ [ :seek, 0 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_regexp_other_block
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal 5, reader.index(/5\d/, 0, 2)
            assert_equal [ [ :seek, 0 ], [ :read, 5 ], [ :seek, 5 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_regexp_cross_block
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal 4, reader.index(/4\d/, 0, 2)
            assert_equal [ [ :seek, 0 ], [ :read, 5 ], [ :seek, 5 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_regexp_none
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal nil, reader.index(/3\s/, 0, 2)
            assert_equal [ [ :seek, 0 ], [ :read, 5 ], [ :seek, 5 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_regexp_with_offset
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal 5, reader.index(/5\d/, 5, 2)
            assert_equal [ [ :seek, 5 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_regexp_none_with_offset
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal nil, reader.index(/4\d/, 5, 2)
            assert_equal [ [ :seek, 5 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_list_first_block
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal [3, 0], reader.index(['34', /7\d/], 0, 2)
            assert_equal [ [ :seek, 0 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_list_first_block_second_token
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal [3, 1], reader.index([/7\d/, '34'], 0, 2)
            assert_equal [ [ :seek, 0 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_list_other_block
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal [5, 0], reader.index([/5\d/, '78'], 0, 2)
            assert_equal [ [ :seek, 0 ], [ :read, 5 ], [ :seek, 5 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_list_cross_block
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal [4, 0], reader.index(['45', '78'])
            assert_equal [ [ :seek, 0 ], [ :read, 5 ], [ :seek, 5 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_list_none
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal [nil, nil], reader.index(['46', /7\s/], 0, 2)
            assert_equal [ [ :seek, 0 ], [ :read, 5 ], [ :seek, 5 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_list_with_offset
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal [5, 0], reader.index(['56', /3\d/], 5, 2)
            assert_equal [ [ :seek, 5 ], [ :read, 5 ] ], io.operations
          end
        end

        def test_index_list_none_with_offset
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal [nil, nil], reader.index(['45', /3\d/], 5, 2)
            assert_equal [ [ :seek, 5 ], [ :read, 5 ] ], io.operations
          end
        end

      end

    end

  end

end
