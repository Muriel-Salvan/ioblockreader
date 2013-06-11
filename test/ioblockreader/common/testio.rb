require 'stringio'

module IOBlockReaderTest

  module Common

    # Test IO used in test cases, to check interactions between IOBlockReader and IO objects.
    class TestIO < StringIO

      def initialize(*args)
        super(*args)
        @operations = []
      end

      def read(*args)
        @operations << [ :read, args[0] ]
        super(*args)
      end

      def seek(*args)
        @operations << [ :seek, args[0] ]
        super(*args)
      end

      def operations
        operations = @operations
        @operations = []
        return operations
      end

    end

  end

end
