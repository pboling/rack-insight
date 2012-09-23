module Rack::Insight
  class RedisPanel < Panel
    require "rack/insight/panels/redis_panel/stats"

    def initialize(app)
      super

      unless is_probing?
        probe(self) do
          if defined?(Redis::Client)
            # Redis >= 3.0.0
            instrument "Redis::Client" do
              instance_probe :call
            end
          elsif defined?(Redis)
            # Redis < 3.0.0
            instrument "Redis" do
              instance_probe :call_command
            end
          end
        end
      end
    end

    def request_start(env, start)
      @stats = Stats.new
    end

    def request_finish(env, status, headers, body, timing)
      store(env, @stats)
      @stats = nil
    end

    def after_detect(method_call, timing, args, message)
      @stats.record_call(timing.duration, args, method_call)
    end

    def heading_for_request(number)
      stats = retrieve(number).first
      "Redis: %.2fms (#{stats.queries.size} calls)" % stats.time
    end

    def content_for_request(number)
      render_template "panels/redis", :stats => retrieve(number).first
    end
  end
end
