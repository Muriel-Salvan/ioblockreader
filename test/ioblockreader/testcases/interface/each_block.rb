module IOBlockReaderTest

  module TestCases

    module Interface

      # Test [] interface of IOBlockReader
      class EachBlock < ::Test::Unit::TestCase

        include IOBlockReaderTest::Common::Helpers

        def test_each_block_from_beginning_to_end_round
          with('0123456789', :block_size => 2) do |io, reader|
            blocks = []
            reader.each_block { |data| blocks << data.clone }
            assert_equal [ '01', '23', '45', '67', '89' ], blocks
          end
        end

        def test_each_block_from_beginning_to_end_not_round
          with('0123456789', :block_size => 3) do |io, reader|
            blocks = []
            reader.each_block { |data| blocks << data.clone }
            assert_equal [ '012', '345', '678', '9' ], blocks
          end
        end

        def test_each_block_from_offset_to_end
          with('0123456789', :block_size => 3) do |io, reader|
            blocks = []
            reader.each_block(4) { |data| blocks << data.clone }
            assert_equal [ '45', '678', '9' ], blocks
          end
        end

        def test_each_block_with_range
          with('0123456789', :block_size => 3) do |io, reader|
            blocks = []
            reader.each_block(4..7) { |data| blocks << data.clone }
            assert_equal [ '45', '67' ], blocks
          end
        end

        def test_each_block_with_range_in_same_block
          with('0123456789', :block_size => 5) do |io, reader|
            blocks = []
            reader.each_block(6..8) { |data| blocks << data.clone }
            assert_equal [ '678' ], blocks
          end
        end

        def test_each_block_with_range_exceeding_end
          with('0123456789', :block_size => 3) do |io, reader|
            blocks = []
            reader.each_block(7..15) { |data| blocks << data.clone }
            assert_equal [ '78', '9' ], blocks
          end
        end

      end

    end

  end

end
