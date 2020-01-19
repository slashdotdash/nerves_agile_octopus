import Config

config :logger, :console, level: :debug
config :logger, backends: [:console]

config :inky, hal_module: InkyHostDev.HAL

config :nerves_agile_octopus, NervesAgileOctopus, NervesAgileOctopus.FileImpl

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
