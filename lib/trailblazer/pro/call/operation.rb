module Trailblazer
  module Pro
    module Call
      module Operation
        # This is the monkey-patch for {Operation.call}.
        # Here we decide whether to use tracing, and what to render,
        # or if we should bypass tracing.
        def call_with_public_interface(options, flow_options, **circuit_options)
          trace_strategy, present_options_merge = Pro::Session.trace_guards.(self, options)

          if trace_strategy
            # trace_strategy.invoke(activity, [ctx, {}], present_options: present_options_merge)
            super(options, flow_options, invoke_class: trace_strategy, **circuit_options, present_options: present_options_merge)
          else
            super
          end
        end
      end # Operation
    end
  end
end
