IOBlockReader
=============

Ruby library giving block-buffered and cached read over IO objects with a String-like interface. Ideal to parse big files as Strings, limiting memory consumption.

## Install

``` bash
gem install ioblockreader
```

## Usage

``` ruby
# Require the library
require 'ioblockreader'

# Open an IO
File.open('my_big_file', 'rb') do |file|

  # Get an IOBlockReader on it
  content = IOBlockReader.init(file)

  # Access it directy
  puts "Content: " + content[10..20]

  # Perform a search
  puts "Search 0123: " + content.index('0123')

end
```

## API

### IOBlockReader.init(io, options = {})

Parameters:
* **io** ( _IO_ ): The IO object used to give the String interface
* **options** (<em>map< Symbol, Object ></em>): Additional options:
  * **:block_size** ( _Fixnum_ ): The block size in bytes used internally. [default = 268435456]
  * **:blocks_in_memory** ( _Fixnum_ ): Maximal number of blocks in memory. If it is required to load more blocks than this value for a single operation, this value is ignored. [default = 2]

Result:
* _IOBlockReader_: The IO Block Reader ready for use

Example:
```
content = IOBlockReader.init(file, :block_size => 32768, :blocks_in_memory => 5)
```

### IOBlockReader#[](range)

Parameters:
* **range** ( _Fixnum_ or _Range_ ): Range to extract

Result:
* _String_: The resulting data

Example:
```
single_char = content[10]
substring = content[10..20]
```

### IOBlockReader#index(token, offset = 0, max_size_regexp = 32)

Parameters:
* **token** ( _String_ , _Regexp_ or <em>list< Object ></em>): Token to be found. Can be a list of tokens.
* **offset** ( _Fixnum_ ): Offset starting the search [optional = 0]
* **max_size_regexp** ( _Fixnum_ ): Maximal number of characters the match should take in case of a Regexp token. Ignored if token is a String. [optional = 32]

Result:
* _Fixnum_: Index of the token (or the first one found from the given token list), or nil if none found.
* _Fixnum_: In case token was an Array, return the index of the matching token in the array, or nil if none found.

Example:
```
# Simple string search
i = content.index('search string')

# Simple string search from a given offset
i = content.index('search string', 20)

# Regexp search: have to specify the maximal token length
i = content.index(/search \d words/, 0, 14)

# Regexp search from a given offset
i = content.index(/search \d words/, 20, 14)

# Search for multiple strings at once: will stop on the first one encountered
i, token_index = content.index( [ 'search string', 'another string' ] )

# Search for multiple tokens at once from a given offset: don't forget token length if using Regexp
i, token_index = content.index( [ 'search string', /another f.....g string/ ], 20, 22)
```

## Contact

Want to contribute? Have any questions? [Contact Muriel!](muriel@x-aeon.com)
