defmodule FzHttp.Config.Errors do
  alias FzHttp.Config.Definition
  require Logger

  @env_doc_url "https://www.firezone.dev/docs/reference/env-vars/#environment-variable-listing"

  def raise_error!(errors) do
    errors
    |> format_error()
    |> raise()
  end

  defp format_error({{nil, ["is required"]}, metadata}) do
    module = Keyword.fetch!(metadata, :module)
    key = Keyword.fetch!(metadata, :key)

    [
      "Missing required configuration value for '#{key}'.",
      "## How to fix?",
      env_example(key),
      db_example(key),
      format_doc(module, key)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

  defp format_error({values_and_errors, metadata}) do
    source = Keyword.fetch!(metadata, :source)
    module = Keyword.fetch!(metadata, :module)
    key = Keyword.fetch!(metadata, :key)

    [
      "Invalid configuration for '#{key}' retrieved from #{source(source)}.",
      "Errors:",
      format_errors(module, key, values_and_errors),
      format_doc(module, key)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

  defp format_error(errors) do
    error_messages = Enum.map(errors, &format_error(&1))

    (["Found #{length(errors)} configuration errors:"] ++ error_messages)
    |> Enum.join("\n\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n")
  end

  defp source({:app_env, key}), do: "application environment #{key}"
  defp source({:env, key}), do: "environment variable #{FzHttp.Config.Resolver.env_key(key)}"
  defp source({:db, key}), do: "database configuration #{key}"
  defp source(:default), do: "default value"

  defp format_errors(module, key, values_and_errors) do
    {_type, {_resolve_opts, _validate_opts, _dump_opts, debug_opts}} =
      Definition.fetch_spec_and_opts!(module, key)

    sensitive? = Keyword.get(debug_opts, :sensitive, false)

    values_and_errors
    |> List.wrap()
    |> Enum.map_join("\n", fn {value, errors} ->
      " - `#{format_value(sensitive?, value)}`: #{Enum.join(errors, ", ")}"
    end)
  end

  defp format_value(true, _value), do: "**SENSITIVE-VALUE-REDACTED**"
  defp format_value(false, value), do: inspect(value)

  defp format_doc(module, key) do
    case module.fetch_doc(key) do
      {:error, :module_not_found} ->
        nil

      {:error, :chunk_not_found} ->
        nil

      :error ->
        nil

      {:ok, doc} ->
        """
        ## Documentation

        #{doc}

        You can find more information on configuration here: #{@env_doc_url}
        """
    end
  end

  def legacy_key_used(key, legacy_key, removed_at) do
    Logger.warn(
      "A legacy configuration option '#{legacy_key}' is used and it will be removed in v#{removed_at}. " <>
        "Please use '#{FzHttp.Config.Resolver.env_key(key)}' configuration option instead."
    )
  end

  def invalid_spec(key, opts) do
    raise "unknown options #{inspect(opts)} for configuration #{inspect(key)}"
  end

  defp env_example(key) do
    """
    ### Using environment variables

    You can set this configuration via environment variable by adding it to `.env` file:

        #{FzHttp.Config.Resolver.env_key(key)}=YOUR_VALUE
    """
  end

  defp db_example(key) do
    if key in FzHttp.Config.Configuration.__schema__(:fields) do
      """
      ### Using database

      Or you can set this configuration in the database by either setting it via the admin panel,
      or by running an SQL query:

          cd $HOME/.firezone
          docker compose exec postgres psql \\
            -U postgres \\
            -h 127.0.0.1 \\
            -d firezone \\
            -c "UPDATE configurations SET #{key} = 'YOUR_VALUE'"
      """
    end
  end
end
