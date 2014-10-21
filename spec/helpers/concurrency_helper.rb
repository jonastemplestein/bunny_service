module BunnyService::ConcurrencyHelper
  # Returns a proc that blocks until a it has been run n times concurrently
  def block_until_thread_count(n, return_value="success")
    i = 0
    Proc.new do
      i += 1
      while i < n; end # wait for other thread to increment shared counter
      return_value
    end
  end
end
