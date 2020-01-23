import Config

config :logger, :console, level: :debug
config :logger, backends: [:console]

config :nerves_agile_octopus, :fetch_unit_rates, NervesAgileOctopus.Agile.FileImpl

config :nerves_agile_octopus, :viewport, %{
  name: :main_viewport,
  default_scene: {NervesAgileOctopus.Scenes.Main, nil},
  size: {212, 104},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Glfw
    }
  ]
}
