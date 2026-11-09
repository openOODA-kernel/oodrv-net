# `oodrv-net`

Ring-3 zero-copy NIC RX/TX DMA descriptor-ring driver, pktio TLS/pacing packet rings, RDMA / RoCEv2 / InfiniBand queue-pair & memory-region `rkey`/`lkey` capability guard, Wi-Fi 802.11, Bluetooth HCI, 5G/LTE WWAN baseband, and IEEE 802.1Qbv TSN / CAN-FD automotive bus suite for [openOODA](https://openOODA.org) (`L1` • [`@openOODA-kernel`](https://github.com/openOODA-kernel)) — split out of `oodrv-io`.

- **Personas / Subcommands**: `oodrv-net`, `oodrv-rdma`, `oodrv-wireless`, `oodrv-bus`, `status`, `verify`, `inspect [path]`, `load <path>`, `about`
- **Driver verbs**: `nic`, `pktio`, `rdma`, `tsn-canfd`, `wifi80211`, `bt-hci`, `wwan`
- **Capabilities (`CapReg64`)**: `FsReadCap`, `FsWriteCap`, `DmaCap`, `MmioCap`, `IrqCap`, `FrameCap`, `NetCap`, `TcpCap`, `UdpCap`, `TimeCap`
- **Bundle**: `@kernel` (`oopm install @kernel` or `oopm install oodrv-net`)

## Usage

```sh
oodrv-net status           # Inspect NIC DMA rings, pktio TLS offload, RDMA QP guard & radio drivers
oodrv-net verify           # Verify zero-copy RX/TX descriptor ring and capability-gate invariants
oodrv-net inspect [path]   # Inspect interface counters & ring capabilities (default /proc/net/dev)
oodrv-net nic              # Run the zero-copy NIC RX/TX DMA ring self-test
oodrv-net rdma             # Run the RDMA QP + MR rkey/lkey admit-gate self-test
oodrv-net wifi80211        # Run the 802.11 beacon/scan/PS-Poll self-test
oodrv-net tsn-canfd        # Run the 802.1Qbv TAS GCL + CAN-FD BRS arbitration self-test
oodrv-net about
```

## Build & Test

```sh
make build
make test
```
