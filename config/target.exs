import Config

config :nerves_agile_octopus, fetch_unit_rates: NervesAgileOctopus.Agile.ApiImpl

config :nerves_agile_octopus, :viewport, %{
  name: :main_viewport,
  default_scene: {NervesAgileOctopus.Scenes.Main, nil},
  size: {212, 104},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: ScenicDriverInky,
      opts: [
        type: :phat,
        accent: :red,
        opts: %{
          border: :black
        }
      ]
    }
  ]
}

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.

config :shoehorn,
  init: [:nerves_runtime, :nerves_network, :nerves_init_gadget],
  app: Mix.Project.config()[:app]

# Nerves Runtime can enumerate hardware devices and send notifications via
# SystemRegistry. This slows down startup and not many programs make use of
# this feature.

config :nerves_runtime, :kernel, use_system_registry: false

# Authorize the device to receive firmware using your public key.
# See https://hexdocs.pm/nerves_firmware_ssh/readme.html for more information
# on configuring nerves_firmware_ssh.

keys =
  [
    Path.join([System.user_home!(), ".ssh", "id_rsa.pub"]),
    Path.join([System.user_home!(), ".ssh", "id_ecdsa.pub"]),
    Path.join([System.user_home!(), ".ssh", "id_ed25519.pub"])
  ]
  |> Enum.filter(&File.exists?/1)

if keys == [],
  do:
    Mix.raise("""
    No SSH public keys found in ~/.ssh. An ssh authorized key is needed to
    log into the Nerves device and update firmware on it using ssh.
    See your project's config.exs for this error message.
    """)

config :nerves_firmware_ssh,
  authorized_keys: Enum.map(keys, &File.read!/1)

# Configure nerves_init_gadget.
# See https://hexdocs.pm/nerves_init_gadget/readme.html for more information.

# Setting the node_name will enable Erlang Distribution.
# Only enable this for prod if you understand the risks.
node_name = if Mix.env() != :prod, do: "nerves_agile_octopus"

# config :nerves_init_gadget,
#   ifname: "usb0",
#   address_method: :dhcpd,
#   mdns_domain: "nerves.local",
#   node_name: node_name,
#   node_host: :mdns_domain

config :nerves_init_gadget,
  mdns_domain: "nerves.local",
  node_name: node_name,
  node_host: :mdns_domain,
  ifname: "wlan0",
  address_method: :dhcp

# Configure wireless settings

key_mgmt = System.get_env("NERVES_NETWORK_KEY_MGMT") || "WPA-PSK"

config :nerves_network, regulatory_domain: "GB"

config :nerves_network, :default,
  wlan0: [
    ssid: System.get_env("NERVES_NETWORK_SSID"),
    psk: System.get_env("NERVES_NETWORK_PSK"),
    key_mgmt: String.to_atom(key_mgmt)
  ]

config :tzdata, :autoupdate, :disabled
config :tzdata, :data_dir, "/root/elixir_tzdata_data"

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.target()}.exs"
