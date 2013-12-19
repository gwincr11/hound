defmodule Hound do
  use Application.Behaviour

  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, options) do
    Hound.Supervisor.start_link(options)
  end

  def get_driver_info do
    :gen_server.call(:hound, :driver_info)
  end

  def start(options // []) do
    :application.start :hound, options
  end
end

defrecord Hound.Info, [driver: Hound.JsonDriver, driver_options: nil, sessions: []]