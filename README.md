# Nerves Agile Octopus

Display [Agile Octopus](https://octopus.energy/agile/) electricity prices on an Inky pHAT display connected to a Raspberry Pi using [Nerves](https://nerves-project.org/).

![Nerves Agile Octopus](assets/nerves_agile_octopus.png "Nerves Agile Octopus")

Agile prices are fetched from the Octopus API each day at 16:01. Prices for the next 24hrs, in half hourly blocks, are shown. The left hand block is the current price which is also labelled with the time period. The prices are updated every half an hour.

Each time block is coloured based upon its electricity cost:

- White (< 8p/kWh)
- Black (8-20p/kWh)
- Red (> 20p/kWh)

## Targets

Nerves applications produce images for hardware targets based on the `MIX_TARGET` environment variable. If `MIX_TARGET` is unset, `mix` builds an
image that runs on the host (e.g., your laptop). This is useful for executing logic tests, running utilities, and debugging. Other targets are represented by a short name like `rpi3` that maps to a Nerves system image for that platform. All of this logic is in the generated `mix.exs` and may be customized. For more information about targets see: https://hexdocs.pm/nerves/targets.html#content

## Getting Started

To start your Nerves app:
  * `export MIX_TARGET=my_target` or prefix every command with
    `MIX_TARGET=my_target`. For example, `MIX_TARGET=rpi3`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`

In a single command:

```
export MIX_TARGET=my_target
mix do deps.get, firmware, firmware.burn
```

Or:

```
MIX_TARGET=<target> mix do deps.get, firmware, firmware.burn
```

### Deploying firmware to host device via SSH

First, generate an `upload.sh` script:

```
export MIX_TARGET=my_target
mix firmware.gen.script
```

Then build a firmware image and upload it to the target device via SSH:

```
export MIX_TARGET=my_target
mix deps.get
mix firmware
./upload.sh
```

### Running locally

A simulation of the Inky pHAT display can be run locally for convenience of development and testing.

First, fetch the Agile Octopus standard unit rates for your tariff and store the JSON data to a local file so that it can be read from disk, instead of being fetched from the Octopus API each time.

```
curl "https://api.octopus.energy/v1/products/AGILE-18-02-21/electricity-tariffs/E-1R-AGILE-18-02-21-H/standard-unit-rates/" > priv/agile_octopus_unit_rates.json
```

Then run `iex -S mix run` OR `mix run --no-halt`
