require 'ioblockreader/datablock'

module IOBlockReader

  # Class giving a String-like interface over an IO, reading it by blocks.
  # Very useful to access big files' content as it was a String containing the whole file's content.
  class IOBlockReader

    # Constructor
    #
    # Parameters::
    # * *io* (_IO_): The IO object used to give the String interface
    # * *options* (<em>map<Symbol,Object></em>): Additional options:
    #   * *:block_size* (_Fixnum_): The block size in bytes used internally. [default = 268435456]
    #   * *:blocks_in_memory* (_Fixnum_): Maximal number of blocks in memory. If it is required to load more blocks than this value for a single operation, this value is ignored. [default = 2]
    def initialize(io, options = {})
      # The underlying IO
      @io = io
      # Parse options
      @block_size = options[:block_size] || 268435456
      @blocks_in_memory = options[:blocks_in_memory] || 2
      # The blocks
      @blocks = []
      # The last accessed block, used as a cache for quick [] access
      @cached_block = nil
      @cached_block_end_offset = nil
    end

    # Get a subset of the data.
    # DO NOT USE NEGATIVE INDEXES.
    #
    # Parameters::
    # * *range* (_Fixnum_ or _Range_): Range to extract
    # Result::
    # * _String_: The resulting data
    def [](range)
      #puts "[IOBlockReader] - [](#{range.inspect})"
      #display_current_blocks
      if (range.is_a?(Fixnum))
        # Use the cache if possible
        return @cached_block.data[range - @cached_block.offset] if ((@cached_block != nil) and (range >= @cached_block.offset) and (range < @cached_block_end_offset))
        #puts "[IOBlockReader] - [](#{range.inspect}) - Cache miss"
        # Separate this case for performance
        single_block_index, offset_in_block = range.divmod(@block_size)
        # First check if all blocks are already loaded
        if ((block = @blocks[single_block_index]) == nil)
          read_needed_blocks([single_block_index], single_block_index, single_block_index)
          block = @blocks[single_block_index]
        else
          block.touch
        end
        set_cache_block(block)
        return block.data[offset_in_block]
      else
        # Use the cache if possible
        return @cached_block.data[range.first - @cached_block.offset..range.last - @cached_block.offset] if ((@cached_block != nil) and (range.first >= @cached_block.offset) and (range.last < @cached_block_end_offset))
        first_block_index, first_offset_in_block = range.first.divmod(@block_size)
        last_block_index, last_offset_in_block = range.last.divmod(@block_size)
        #puts "[IOBlockReader] - [](#{range.inspect}) - Cache miss: load blocks #{first_block_index} - #{last_block_index}"
        # First check if all blocks are already loaded
        if (first_block_index == last_block_index)
          if ((block = @blocks[first_block_index]) == nil)
            read_needed_blocks([first_block_index], first_block_index, last_block_index)
            block = @blocks[first_block_index]
          else
            block.touch
          end
          set_cache_block(block)
          return block.data[first_offset_in_block..last_offset_in_block]
        else
          # Get all indexes to be loaded
          indexes_needing_loading = []
          (first_block_index..last_block_index).each do |block_index|
            if ((block = @blocks[block_index]) == nil)
              indexes_needing_loading << block_index
            else
              block.touch
            end
          end
          read_needed_blocks(indexes_needing_loading, first_block_index, last_block_index) if (!indexes_needing_loading.empty?)
          # Now read across the blocks
          result = @blocks[first_block_index].data[first_offset_in_block..-1].dup
          (first_block_index+1..last_block_index-1).each do |block_index|
            result.concat(@blocks[block_index].data)
          end
          result.concat(@blocks[last_block_index].data[0..last_offset_in_block])
          # There are more chances that the last block will be accessed again. Cache this one.
          set_cache_block(@blocks[last_block_index])
          return result
        end
      end
    end

    # Perform a search of a token (or a list of tokens) in the IO.
    # Warning: The token(s) to be found have to be smaller than the block size given to the constructor, otherwise they won't be found (you've been warned!). If you really need to search for tokens bigger than block size, extract the data using [] operator first, and then use index on it ; it will however make a complete copy of the data in memory prior to searching tokens.
    #
    # Parameters::
    # * *token* (_String_, _Regexp_ or <em>list<Object></em>): Token to be found. Can be a list of tokens. Please note than using a list of tokens is slower than using a single Regexp.
    # * *offset* (_Fixnum_): Offset starting the search [optional = 0]
    # * *max_size_regexp* (_Fixnum_): Maximal number of characters the match should take in case of a Regexp token. Ignored if token is a String. [optional = 32]
    # Result::
    # * _Fixnum_: Index of the token (or the first one found from the given token list), or nil if none found.
    # * _Fixnum_: In case token was an Array, return the index of the matching token in the array, or nil if none found.
    def index(token, offset = 0, max_size_regexp = 32)
      #puts "[IOBlockReader] - index(#{token.inspect}, #{offset}, #{max_size_regexp})"
      # Separate the trivial algo for performance reasons
      current_block_index, offset_in_current_block = offset.divmod(@block_size)
      if ((current_block = @blocks[current_block_index]) == nil)
        read_needed_blocks([current_block_index], current_block_index, current_block_index)
        current_block = @blocks[current_block_index]
      else
        current_block.touch
      end
      index_in_block = nil
      index_matching_token = nil
      if (token_is_array = token.is_a?(Array))
        token.each_with_index do |token2, idx|
          index_token2_in_block = current_block.data.index(token2, offset_in_current_block)
          if (index_token2_in_block != nil) and ((index_in_block == nil) or (index_token2_in_block < index_in_block))
            index_in_block = index_token2_in_block
            index_matching_token = idx
          end
        end
      else
        index_in_block = current_block.data.index(token, offset_in_current_block)
      end
      if (index_in_block == nil)
        # We have to search further: across blocks
        # Compute the size of the token to be searched
        token_size = 0
        if token_is_array
          token.each do |token2|
            if (token2.is_a?(String))
              token_size = token2.size if (token2.size > token_size)
            else
              token_size = max_size_regexp if (max_size_regexp > token_size)
            end
          end
        elsif (token.is_a?(String))
          token_size = token.size
        else
          token_size = max_size_regexp
        end
        # Loop on subsequent blocks to search for token
        result = nil
        while ((result == nil) and (!current_block.last_block?))
          #puts "[IOBlockReader] - index(#{token.inspect}, #{offset}, #{max_size_regexp}) - No find in last block #{current_block}. Continuing..."
          # Check that next block is loaded
          if ((next_block = @blocks[current_block_index+1]) == nil)
            read_needed_blocks([current_block_index+1], current_block_index+1, current_block_index+1)
            next_block = @blocks[current_block_index+1]
          else
            next_block.touch
          end
          # Get data across the 2 blocks if needed: enough to search for token_size data only
          if (token_size > 1)
            cross_data = current_block.data[1-token_size..-1] + next_block.data[0..token_size-2]
            #puts "[IOBlockReader] - index(#{token.inspect}, #{offset}, #{max_size_regexp}) - Find token in cross data: #{cross_data.inspect}..."
            if token_is_array
              token.each_with_index do |token2, idx|
                index_token2_in_block = cross_data.index(token2)
                if (index_token2_in_block != nil) and ((index_in_block == nil) or (index_token2_in_block < index_in_block))
                  index_in_block = index_token2_in_block
                  index_matching_token = idx
                end
              end
            else
              index_in_block = cross_data.index(token)
            end
          end
          if (index_in_block == nil)
            #puts "[IOBlockReader] - index(#{token.inspect}, #{offset}, #{max_size_regexp}) - No find in cross blocks #{current_block} / #{next_block}. Continuing..." if (token_size > 1)
            # Search in the next block
            if token_is_array
              token.each_with_index do |token2, idx|
                index_token2_in_block = next_block.data.index(token2)
                if (index_token2_in_block != nil) and ((index_in_block == nil) or (index_token2_in_block < index_in_block))
                  index_in_block = index_token2_in_block
                  index_matching_token = idx
                end
              end
            else
              index_in_block = next_block.data.index(token)
            end
            if (index_in_block == nil)
              # Loop on the next block
              current_block_index += 1
              current_block = next_block
            else
              result = next_block.offset + index_in_block
            end
          else
            result = next_block.offset - token_size + 1 + index_in_block
          end
        end
        if token_is_array
          return result, index_matching_token
        else
          return result
        end
      elsif token_is_array
        return current_block.offset + index_in_block, index_matching_token
      else
        return current_block.offset + index_in_block
      end
    end

    # Iterate over blocks in the data.
    # ! Do not use negative integers in the range.
    #
    # Parameters::
    # * *range* (_Range_ or _Fixnum_): The boundaries of the iteration, or the starting index [default = 0]
    # * _Block_: Code called for each block encountered
    #   * Parameters::
    #   * *data* (_String_): The data
    def each_block(range = 0)
      #puts "[IOBlockReader] - each_block(#{range})"
      # Parse parameters
      begin_offset = range
      end_offset = nil
      if (range.is_a?(Range))
        begin_offset = range.first
        end_offset = range.last
      end

      current_block_index, begin_offset_in_first_block = begin_offset.divmod(@block_size)
      end_offset_block_index, end_offset_in_last_block = ((end_offset == nil) ? [nil, nil] : end_offset.divmod(@block_size))
      # Make sure first block is loaded
      if ((current_block = @blocks[current_block_index]) == nil)
        read_needed_blocks([current_block_index], current_block_index, current_block_index)
        current_block = @blocks[current_block_index]
      else
        current_block.touch
      end
      if (current_block_index == end_offset_block_index)
        # We have a Range in the same block
        if ((begin_offset_in_first_block == 0) and
            (end_offset_in_last_block == current_block.data.size-1))
          yield(current_block.data)
        else
          yield(current_block.data[begin_offset_in_first_block..end_offset_in_last_block])
        end
      else
        # We need to loop, but consider first block differently as it might be partially given
        if (begin_offset_in_first_block == 0)
          yield(current_block.data)
        else
          yield(current_block.data[begin_offset_in_first_block..-1])
        end
        if (!current_block.last_block?)
          # Now loop on all subsequent blocks unless we get to the last one
          finished = false
          while (!finished)
            # Read next block
            current_block_index += 1
            if ((current_block = @blocks[current_block_index]) == nil)
              read_needed_blocks([current_block_index], current_block_index, current_block_index)
              current_block = @blocks[current_block_index]
            else
              current_block.touch
            end
            if (end_offset_block_index == current_block_index)
              # We arrived on the last block of the Range
              if (end_offset_in_last_block == current_block.data.size-1)
                yield(current_block.data)
              else
                yield(current_block.data[0..end_offset_in_last_block])
              end
              finished = true
            else
              yield(current_block.data)
              finished = current_block.last_block?
            end
          end
        end
      end
    end

    # Get the block containing a given offset.
    # This method is mainly used to provide some low-level access for processes needing great parsing performance.
    #
    # Parameters::
    # * *offset* (_Fixnum_): The offset to be accessed [default = 0]
    # Return::
    # * _String_: The block of data containing this offset
    # * _Fixnum_: The beginning offset of this data block
    # * _Boolean_: Is this block the last one?
    def get_block_containing_offset(offset = 0)
      #puts "[IOBlockReader] - get_block_containing_offset(#{offset})"
      # Use the cache if possible
      return [ @cached_block.data, @cached_block.offset, @cached_block.last_block? ] if ((@cached_block != nil) and (offset >= @cached_block.offset) and (offset < @cached_block_end_offset))
      #puts "[IOBlockReader] - get_block_containing_offset(#{offset}) - Cache miss"
      single_block_index, _ = offset.divmod(@block_size)
      if ((block = @blocks[single_block_index]) == nil)
        read_needed_blocks([single_block_index], single_block_index, single_block_index)
        block = @blocks[single_block_index]
      else
        block.touch
      end
      set_cache_block(block)
      return block.data, block.offset, block.last_block?
    end

    private

    # Set the new cache block
    #
    # Parameters::
    # * *block* (_DataBlock_): Block to be cached
    def set_cache_block(block)
      #puts "[IOBlockReader] - Set cached block to offset #{block.offset}"
      @cached_block = block
      @cached_block_end_offset = block.offset + @block_size
    end

    # Read blocks from the IO
    #
    # Parameters::
    # * *indexes_needing_loading* (<em>list<Fixnum></em>): List of indexes to be read
    # * *first_block_index* (_Fixnum_): First block that has to be loaded
    # * *last_block_index* (_Fixnum_): Last block that has to be loaded
    def read_needed_blocks(indexes_needing_loading, first_block_index, last_block_index)
      #puts "[IOBlockReader] - read_needed_blocks([ #{indexes_needing_loading.join(', ')} ], #{first_block_index}, #{last_block_index})"
      # We need to read from the IO
      # First check if we need to remove some blocks prior
      removed_blocks = []
      nbr_freeable_blocks = 0
      other_blocks = (first_block_index > 0) ? @blocks[0..first_block_index-1] : []
      other_blocks.concat(@blocks[last_block_index+1..-1]) if (last_block_index+1 < @blocks.size)
      other_blocks.each do |block|
        nbr_freeable_blocks += 1 if (block != nil)
      end
      nbr_blocks_to_be_loaded = last_block_index - first_block_index + 1
      if ((nbr_freeable_blocks > 0) and
          (nbr_blocks_to_be_loaded + nbr_freeable_blocks > @blocks_in_memory))
        # Need to make some space
        nbr_blocks_to_free = [ nbr_blocks_to_be_loaded + nbr_freeable_blocks - @blocks_in_memory, nbr_freeable_blocks ].min
        # Get the blocks that we remove for future reuse
        other_blocks.
          select { |block| block != nil }.
          sort { |block1, block2| block1.last_access_time <=> block2.last_access_time }.each do |block|
          #puts "[IOBlockReader] - Remove block #{block.offset}"
          removed_blocks << block
          break if (removed_blocks.size == nbr_blocks_to_free)
        end
        # Remove them for real
        @blocks.map! { |block| removed_blocks.include?(block) ? nil : block }
      end
      # Now read the blocks, reusing the ones in removed_blocks if possible
      indexes_needing_loading.each do |block_index|
        # Have to load this block
        block_to_fill = removed_blocks.pop
        block_to_fill = DataBlock.new(@io) if (block_to_fill == nil)
        block_to_fill.fill(block_index * @block_size, @block_size)
        # Update the cached block end offset if it was modified
        @cached_block_end_offset = block_to_fill.offset + @block_size if (block_to_fill == @cached_block)
        @blocks[block_index] = block_to_fill
      end
    end

    # Display current blocks
    def display_current_blocks
      puts "[IOBlockReader] - #{@blocks.size} blocks: #{@blocks.map { |block| (block == nil) ? '[nil]' : block }.join(' ')}"
      puts "[IOBlockReader] - Cached block: #{(@cached_block == nil) ? '[nil]' : @cached_block } - End: #{@cached_block_end_offset}"
    end

  end

end
