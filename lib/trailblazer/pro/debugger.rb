module Trailblazer
  module Pro
    module Debugger
      module_function

      # Called in {Trace::Present.call} as {:render_method}.
      def call(debugger_trace:, activity:, render_wtf: false, renderer:, **options)
        trace_data = render_trace_data(debugger_trace, activity: activity, **options)

        trace_envelope = {
          fields: {
            activity_name:   {stringValue: activity},
            trace:  {stringValue: trace_data},
            created_at: {timestampValue: DateTime.now}, # we're using local client time currently.
          }
        }

        session, stored_trace_id, session_updated = push(trace_envelope, activity: activity, **options)

        debugger_url = "https://ide.trailblazer.to/#{stored_trace_id}"
        # output       = "[TRB PRO] view trace (#{activity}) at #{debugger_url}"
        # output       = Developer::Wtf::Renderer::String.bold(output)
        output       = Developer::Wtf::Renderer::String.bold("[TRB PRO] view trace (#{activity}) at ")
        output += debugger_url # DISCUSS: what do we want bold here?

        if render_wtf
          # TODO: take the color_map from outside caller.
          wtf_output = Developer::Trace::Present.render(debugger_trace: debugger_trace, renderer: renderer, color_map: Developer::Wtf::Renderer::DEFAULT_COLOR_MAP) # , activity: activity

          output = [wtf_output, output].join("\n")
        end

        returned_values = [session, stored_trace_id, debugger_url, trace_envelope, session_updated]

        return output, returned_values
      end

      def render_trace_data(debugger_trace, activity:, **)
        flat_tree_json = debugger_trace.to_a.collect do |debugger_node|

          # TODO: do we even need to grab tw by path here?
          introspect_nodes_node = OpenStruct.new(task: debugger_node.task)
          tw_render = Developer::Render::TaskWrap.render_for(debugger_node.activity, introspect_nodes_node)

          # This rendering code has deep knowledge of Trace/pro/v1 tracing interface.
          {
            id:             debugger_node.id.to_s,
            runtime_id:     debugger_node.runtime_id,
            level:          debugger_node.level,
            label:          debugger_node.label,
            ctx_snapshots: {
              before: debugger_node.snapshot_before.data[:ctx_variable_changeset].collect { |name, hash, has_changed| [name, {version: hash.to_s, has_changed: !!has_changed}] },
              after:  debugger_node.snapshot_after ?

              debugger_node.snapshot_after.data[:ctx_variable_changeset].collect { |name, hash, has_changed| [name, {version: hash.to_s, has_changed: !!has_changed}] } # FIXME: of course, this is horrible.
              : [],
            },

            rendered_task_wrap: tw_render,
          }
        end

        JSON.dump(
          nodes:              flat_tree_json,
          variable_versions:  debugger_trace.to_h[:variable_versions].to_h,
          pro_version: Pro::VERSION.to_s,
        )
      end

      class Push < Trailblazer::Activity::Railway
        step :session_initialized?,
          Output(:failure) => Path(track_color: :signin, connect_to: Track(:rebuild)) do # FIXME: move to after {valid?}
            # Signin only consumes {:api_key} and friends and doesn't know about {:session}.
            step Subprocess(Trailblazer::Pro::Trace::Signin),
              In() => :session_to_args#,
              # Out() => Trace::Signin::SESSION_VARIABLE_NAMES
          end

        step Trace.method(:valid?), In() => :session_to_args, Inject() => [:now],
          Output(:failure) => Path(track_color: :refresh, connect_to: Track(:rebuild)) do
            step Subprocess(Trailblazer::Pro::Trace::Refresh), In() => :session_to_args
          end

        step :rebuild_session, magnetic_to: :rebuild # TODO: assert that success/failure go to right Track.

        step Subprocess(Trailblazer::Pro::Trace::Store),
          In() => :session_to_args,
          In() => [:data_to_store]

        def session_initialized?(ctx, session:, **)
          session.is_a?(Session)
        end

        def rebuild_session(ctx, session:, **)
          session_params = ctx.to_h.slice(*Trace::Signin::SESSION_VARIABLE_NAMES)

          session = Session.new(
            **session.to_h,  # old data
            **session_params, # new input
          )

          ctx[:session] = session
          ctx[:session_updated] = true
        end

        def session_to_args(ctx, session:, **)
          session.to_h
        end
      end # Push

      def push(trace_data, activity:, now: DateTime.now, **options)
        # signal, (ctx, _) = Trailblazer::Developer.wtf?(Push, [{now: now, data_to_store: trace_data, **options}, {}])
        _signal, (ctx, _) = Trailblazer::Activity.(Push, {now: now, data_to_store: trace_data, **options})
        # signal, (ctx, _) = Push.invoke([{now: now, data_to_store: trace_data, **options}, {}])

        session         = ctx[:session]
        stored_trace_id = ctx[:id]
        session_updated = ctx[:session_updated]

        return session, stored_trace_id, session_updated
      end
    end # Debugger
  end
end
