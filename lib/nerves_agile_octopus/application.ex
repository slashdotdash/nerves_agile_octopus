defmodule NervesAgileOctopus.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NervesAgileOctopus.Supervisor]

    children =
      [
        # Children for all targets
        # Starts a worker by calling: NervesAgileOctopus.Worker.start_link(arg)
        # {NervesAgileOctopus.Worker, arg},
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  # def children(:host) do
  #   [
  #     # Children that only run on the host
  #     # Starts a worker by calling: NervesAgileOctopus.Worker.start_link(arg)
  #     # {NervesAgileOctopus.Worker, arg},
  #   ]
  # end

  def children(_target) do
    main_viewport_config = Application.get_env(:nerves_agile_octopus, :viewport)
    timezone = Application.get_env(:nerves_agile_octopus, :timezone)

    [
      {NervesAgileOctopus.Agile.StandardUnitRates, timezone: timezone},
      {Scenic, viewports: [main_viewport_config]}
    ]
  end

  def target() do
    Application.get_env(:nerves_agile_octopus, :target)
  end
end
