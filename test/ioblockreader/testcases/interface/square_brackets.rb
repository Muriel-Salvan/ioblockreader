module IOBlockReaderTest

  module TestCases

    module Interface

      # Test [] interface of IOBlockReader
      class SquareBrackets < ::Test::Unit::TestCase

        include IOBlockReaderTest::Common::Helpers

        def test_square_brackets_range_same_block
          with('0123456789', :block_size => 5) do |io, reader|
            assert_equal '123', reader[1..3]
          end
        end

        def test_square_brackets_range_cross_1_block
          with('0123456789', :block_size => 3) do |io, reader|
            assert_equal '123', reader[1..3]
          end
        end

        def test_square_brackets_range_cross_2_blocks
          with('0123456789', :block_size => 3) do |io, reader|
            assert_equal '123456', reader[1..6]
          end
        end

        def test_square_brackets_single
          with('0123456789') do |io, reader|
            assert_equal '1'[0], reader[1]
          end
        end

      end

    end

  end

end
