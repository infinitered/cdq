module Bacon
  class Context
    # Executes a given block on an async concurrent GCD queue (which is a
    # different thread) and returns the return value of the block, which is
    # expected to be either true or false.
    def on_thread(&block)
      @result = false
      group = Dispatch::Group.new
      Dispatch::Queue.concurrent.async(group) do
        @result = block.call
      end
      group.wait
      @result
    end
  end
end
