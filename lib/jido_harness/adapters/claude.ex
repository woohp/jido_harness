defmodule Jido.Harness.Adapters.Claude do
  @moduledoc """
  Claude Code provider profile using claude-agent-acp.

  The `resume_session_at` provider option names a message UUID in the session being
  forked or resumed: Claude Code keeps history only up to and including that entry.

  The client advertises ACP `session.compaction`, so Claude's context compactions arrive
  as `compaction_update` and `compaction_summary_chunk` updates (provider events) rather
  than as a synthetic tool call.
  """
  @behaviour Jido.Harness.Adapter

  alias Jido.Harness.{AdapterSpec, Adapters.Helpers, Capabilities}

  @impl true
  def spec do
    %AdapterSpec{
      provider: :claude,
      name: "Claude Code",
      executable: "claude",
      docs_url: "https://docs.anthropic.com/en/docs/claude-code",
      capabilities: %Capabilities{
        streaming?: true,
        tool_calls?: true,
        tool_results?: true,
        thinking?: true,
        resume?: true,
        usage?: true,
        native_cancel?: true
      },
      acp_agent:
        Jido.Harness.ACPAgentSpec.adapter(
          "claude-agent-acp",
          "@agentclientprotocol/claude-agent-acp@0.101.0",
          %{
            capabilities: %{load_session: true, multimodal: true, dynamic_model: true, usage: true},
            turn_options: [:attachments, :content],
            configuration_options: [:model],
            session_provider_options: :adapter
          }
        ),
      normalized_options: [:model, :provider_session_id, :mcp_config, :attachments],
      provider_options: [:resume_session_at],
      install: %{npm: "@anthropic-ai/claude-code"}
    }
  end

  @impl true
  def status(config),
    do:
      Helpers.status(
        :claude,
        spec().executable,
        ["ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_API_KEY", "CLAUDE_CODE_API_KEY"],
        config,
        capabilities: spec().capabilities
      )

  @impl true
  def acp_client_capabilities do
    %{"session" => %{"compaction" => %{}}}
  end

  @impl true
  def acp_session_meta(request) do
    case Helpers.provider_options(request.provider_options, [:resume_session_at]) do
      %{resume_session_at: uuid} when is_binary(uuid) ->
        %{"claudeCode" => %{"options" => %{"resumeSessionAt" => uuid}}}

      _options ->
        nil
    end
  end

  @impl true
  def install(_config, options), do: Helpers.install_npm(:claude, "@anthropic-ai/claude-code", options)
end
