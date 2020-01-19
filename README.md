# Nerves Agile Octopus

Display [Agile Octopus](https://octopus.energy/agile/) electricity prices on an Inky pHAT display connected to a Raspberry Pi using [Nerves](https://nerves-project.org/).

## Targets

Nerves applications produce images for hardware targets based on the `MIX_TARGET` environment variable. If `MIX_TARGET` is unset, `mix` builds an
image that runs on the host (e.g., your laptop). This is useful for executing logic tests, running utilities, and debugging. Other targets are represented by a short name like `rpi3` that maps to a Nerves system image for that platform. All of this logic is in the generated `mix.exs` and may be customized. For more information about targets see:

https://hexdocs.pm/nerves/targets.html#content

## Getting Started

To start your Nerves app:
  * `export MIX_TARGET=my_target` or prefix every command with
    `MIX_TARGET=my_target`. For example, `MIX_TARGET=rpi3`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`

In a single command:

```
mix do deps.get, firmware, firmware.burn
```

Or:

```
MIX_TARGET=<target> mix do deps.get, firmware, firmware.burn
```

### Deploying firmware to host via SSH

```
export MIX_TARGET=my_target
mix deps.get
mix firmware
./upload.sh
```
