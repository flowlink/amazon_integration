class Workflow

  def initialize(queue)
    @queue = queue
    @handlers = []
  end

  def register(*deps, &handler)
    @handlers << [ handler, deps ]
  end

  def complete(feed)
    @handlers.each do | handler |
      handler.last.delete feed
    end
    proceed
  end

  def proceed
    @handlers.each_with_index do | handler, index |
      if handler.last.empty?
        @handlers[index] = nil
        [ handler.first.call ].compact.flatten.each do | feed |
          @queue << feed
        end
      end
    end
    @handlers.compact!
  end

end
