class Vigil
  class Poll
    def initialize(n=60)
      @n = n
    end

    def call
      loop do
        _less_often_than_every(@n) do
          yield
        end
      end
    end

    def _less_often_than_every(n_seconds)
      start = Time.now
      yield
      _end = Time.now
      if _end - start < n_seconds
        n = n_seconds - (_end - start)
        puts "Sleeping for #{n} sec."
        sleep n
      end
    end

  end
end
