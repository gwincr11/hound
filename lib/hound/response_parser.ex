defmodule Hound.ResponseParser do
  @moduledoc """
  Defines a behaviour for parsing driver responses
  and provides a default implementation of the behaviour
  """

  require Logger

  @callback handle_response(any, integer, String.t) :: any
  @callback handle_error(Map.t) :: {:error, any}

  defmacro __using__(_) do
    quote do
      @behaviour Hound.ResponseParser

      @before_compile unquote(__MODULE__)

      def parse(path, %HTTPoison.Response{body: raw_content, status_code: code}) do
        body = Hound.ResponseParser.decode_content(raw_content)
        handle_response(path, code, body)
      end

      def handle_response(path, code, body) do
        Hound.ResponseParser.handle_response(__MODULE__, path, code, body)
      end

      defdelegate warning?(message), to: Hound.ResponseParser

      defoverridable [handle_response: 3, warning?: 1]
    end
  end

  @doc """
  Default implementation to handle drivers responses.
  """
  def handle_response(mod, path, code, body)
  def handle_response(_mod, "session", code, %{"sessionId" => session_id}) when code < 300 do
    {:ok, session_id}
  end
  def handle_response(mod, _path, _code, %{"value" => %{"message" => message} = value}) do
    if mod.warning?(message) do
      Logger.warn(message)
      message
    else
      mod.handle_error(value)
    end
  end
  def handle_response(_mod, _path, _code, %{"status" => 0, "value" => value}), do: value
  def handle_response(_mod, _path, code, _body) when code < 400, do: :ok
  def handle_response(_mod, _path, _code, _body), do: :error

  @doc """
  Default implementation to check if the message is a warning
  """
  def warning?(message) do
    Regex.match?(~r/#{Regex.escape("not clickable")}/, message)
  end

  @doc """
  Decodes a response body
  """
  def decode_content([]), do: Map.new
  def decode_content(content), do: Poison.decode!(content)

  defmacro __before_compile__(_env) do
    # We want this to be a fallback
    quote line: -1 do
      @doc """
      Fallback case if we did not match the message in the using module
      """
      def handle_error(%{"message" => message}) do
        {:error, message}
      end
    end
  end
end
