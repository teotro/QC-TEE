# QC-TEE — SoteriaQ Hardware Security Engine

Verilog/VHDL reference implementation of the trusted hardware in
**SoteriaQ: Secure Quantum Computation via Gate-Level Obfuscation from
Untrusted Clouds** (QCE 2026).

SoteriaQ protects a user's quantum circuit from an honest-but-curious cloud
provider by mixing the real control pulses with *decoy* pulses at circuit-
preparation time, and then attenuating the decoy pulses inside the dilution
refrigerator using RF switches driven by trusted hardware. This repository
contains the RTL for that trusted hardware — the *hardware security engine*
that lives inside the 4 K stage of the fridge, decrypts the per-shot *input
bitmap* that tells it which pulses to attenuate, drives the RF switches, and
encrypts an *output bitmap* for the user (for the X-gate output-randomization
layer).

Paper: Trochatos, Xu, Deshpande, Lu, Ding, Szefer, *SoteriaQ*, IEEE QCE 2026.

---

## What the hardware does

Referring to Fig. 3 in the paper, this repo implements the components inside
the green "SoteriaQ" box:

1. **Decryption engine** — AES-128 (GMU/CAESAR core) decrypts the encrypted
   input bitmap arriving from the cloud provider.
2. **Input bitmap memory** — dual-ported BRAM holding the plaintext bitmap
   (1 bit per drive/control channel per 160 dt slot).
3. **Hardware security engine (main controller)** — state machine that
   sequences key setup → bitmap decryption → SHAKE-based post-processing →
   output bitmap encryption; also streams bitmap bits through a shifter and
   FIFO into the RF-switch drive lines.
4. **Attenuation switches** — external SPDT GaAs RF switches (modeled here
   only as the drive-signal outputs on `output_switches`).
5. **Encryption engine** — the same AES core, reused in encrypt mode for the
   returned output bitmap.
6. **TRNG** — the *placeholder* in this RTL is a SHAKE-256 core seeded with a
   fixed value in `main_controller.v` (`data_0`..`data_3`). Replace with a
   real TRNG source for deployment.
7. **UART wrapper (`uart_top_no_fifo.v`)** — bring-up harness that lets a
   host PC push the AES key and encrypted bitmap into the FPGA and read the
   RF-switch drive stream back out.

## Repository layout

```
QC-TEE/
├── Makefile                 Top-level build entry point (see Quick start).
│
├── hardware/                All RTL sources and constraints.
│   ├── create_project.tcl   Vivado batch script: creates project, adds all
│   │                        sources and constraints, sets top, runs
│   │                        synthesis → implementation → bitstream.
│   ├── constraints/
│   │   └── Basys-3-Master.xdc  Pin constraints for the Basys-3 board.
│   │
│   ├── top_with_fifo.v      Top of the security engine: crypto_engine +
│   │                        main controller + SHAKE + bitmap memory +
│   │                        shifter + switch FIFO.
│   ├── uart_top_no_fifo.v   FPGA bring-up wrapper: UART RX/TX around
│   │                        top_with_fifo. Uses the Xilinx BUFG primitive.
│   ├── main_controller.v    Main FSM. Two sub-FSMs:
│   │                          (a) init → decrypt → SHAKE → encrypt → done
│   │                          (b) SHAKE handshake protocol
│   ├── dec_enc_engine.v     crypto_engine — wraps AES_EncDec and sequences
│   │                        block-by-block decrypt/encrypt over bitmap memory.
│   ├── shifter.v            128-bit → 7-bit shifter that streams bitmap
│   │                        words into the switch FIFO (NUM_SWITCHES=7).
│   ├── clog2.v              `CLOG2 / `DIVCLOG2 preprocessor macros.
│   │
│   ├── memory/
│   │   ├── mem_dual.v       Dual-port BRAM (bitmap memory).
│   │   └── fifo-orig.v      Synchronous FIFO (D. Gisselquist, public domain).
│   │
│   ├── uart/
│   │   ├── rxuart.v         wbuart32 RX (Gisselquist, GPL).
│   │   └── txuart.v         wbuart32 TX (Gisselquist, GPL).
│   │
│   ├── shake256/            SHAKE-256 (Keccak-f[1600]) core, Verilog port
│   │   ├── keccak_top.v     of Bernhard Jungk's VHDL implementation,
│   │   ├── control_path.v   adapted by Yale (J. Szefer, S. Tian).
│   │   ├── data_path.v      Used here for post-processing / randomness
│   │   ├── keccak_math.v    derivation between decrypt and encrypt phases.
│   │   ├── keccak_pkg.v
│   │   ├── state_ram.v
│   │   ├── stateram_inference.v
│   │   ├── transform.v
│   │   ├── rc.v
│   │   └── clog2.v          (Package-local copy; identical macros.)
│   │
│   ├── AES/                 GMU CAESAR AES-128 core (VHDL, GPL).
│   │   ├── LICENSE.txt      GPLv3.
│   │   ├── AES_EncDec_sources.txt  Build file list for the EncDec variant.
│   │   └── src/             Core AES sources (Sbox, MixColumns, Round,
│   │       ├── AES_EncDec.vhd      KeyUpdate, top-levels).
│   │       ├── AES_EncDec_Datapath.vhd
│   │       └── ...
│   │
│   └── tb/                  Verilog testbenches.
│       ├── top_with_fifo_tb.v      Main integration TB.
│       ├── decryption_engine_tb.v
│       ├── decryption_encryption_engine_tb.v
│       ├── dec_x_mem_tb.v
│       ├── shifter_tb.v
│       └── DUMMY_ENCRYPTED_DATA.mem  Six 128-bit test-vector bitmaps.
│
├── software/                Host-side FPGA bring-up scripts.
│   ├── uart_loopback_test.py   Serial driver: sends block size + AES key +
│   │                           encrypted bitmap, reads back decrypted
│   │                           bitmap and RF-switch stream.
│   └── utils.py                Helpers for building the input bitmap file
│                               (decoy=1, original=0) and reshaping it to
│                               128-bit words.
│
└── vivado_proj/             Generated by `make bitstream` — not committed.
```

## Quick start

### Prerequisites

- Xilinx Vivado 2020.1 or newer (for synthesis and bitstream generation).
- Python 3 with `pyserial`, `pycryptodome`, and `bitstring` (for the host
  bring-up script).
- `make`.

### 1. Generate the bitstream

```bash
make bitstream
```

This runs `hardware/create_project.tcl` in Vivado batch mode. It creates the
project under `vivado_proj/`, adds all RTL and constraint sources, sets
`uart_top_no_fifo` as top, and runs synthesis → implementation →
`write_bitstream`. The finished bitstream is written to:

```
vivado_proj/qc_tee.runs/impl_1/uart_top_no_fifo.bit
```

### 2. Program the FPGA

Open Vivado Hardware Manager, connect to the Basys-3 board, and program it
with the bitstream above. Alternatively use `open_hw_manager` / `program_hw_devices`
from the Vivado Tcl console.

### 3. Run the UART loopback test

Install Python dependencies once:

```bash
pip install pyserial pycryptodome bitstring
```

Then:

```bash
make loopback PORT=/dev/ttyUSB0 BAUD=115200
```

`PORT` defaults to `/dev/ttyUSB0` and `BAUD` to `115200`; override on the
command line as needed.

The script:
1. Reads `hardware/tb/DUMMY_ENCRYPTED_DATA.mem` (six 128-bit binary lines),
2. Sends the block size (1 byte),
3. Sends a hardcoded all-zero AES-128 key (edit `key = bytes.fromhex(...)`
   in `software/uart_loopback_test.py` to change it),
4. AES-ECB-encrypts each bitmap word and sends it,
5. Reads back the decrypted bitmap, the SHAKE-encrypted output bitmap, and
   112 bytes of RF-switch FIFO output.

### Makefile targets

| Target          | Description                                      |
| --------------- | ------------------------------------------------ |
| `make bitstream`| Run Vivado TCL to synthesise and generate bitstream (default). |
| `make loopback` | Run the UART host script (FPGA must be programmed first). |
| `make clean`    | Remove the generated `vivado_proj/` directory.   |

## Parameters and interfaces

The main parameters of `top_with_fifo` and `uart_top_no_fifo`:

| Parameter              | Default | Meaning                                    |
| ---------------------- | ------- | ------------------------------------------ |
| `AES_KEY_SIZE`         | 128     | AES key width (bits).                      |
| `BITMAP_MEM_WIDTH`     | 128     | Bitmap memory word width.                  |
| `MAX_BITMAP_MEM_DEPTH` | 2048    | Max number of 128-bit bitmap words.        |
| `NUM_SWITCHES`         | 7       | RF drive channels per output word.         |
| `OUT_DATA_WIDTH`       | 128     | Output bitmap word width.                  |
| `TRNG_SEED_WIDTH`      | 128     | Width of TRNG seed for output X-gate mask. |
| `BAUD_RATE`            | 115200  | UART bring-up baud rate.                   |
| `CLK_SPEED`            | 100 MHz | System clock (change to match your board). |

The paper argues the control logic must run at 1–200 MHz to keep up with
IBM's 1dt = 0.222 ns / 160dt = 35.5 ns single-qubit-gate cadence (Sec. VI-C).

## Third-party components and licenses

- `AES/` — GMU CAESAR AES-128 core, © 2014 CERG, GMU — **GPLv3**
  (`AES/LICENSE.txt`).
- `AES/AES-GCM/` — GMU AES-GCM AEAD reference (same authors, same license).
- `shake256/` — Keccak / SHAKE-256, © 2019 Bernhard Jungk, Verilog port by
  Yale (J. Szefer, S. Tian) — **GPLv3**.
- `uart/` — wbuart32 by Dan Gisselquist / Gisselquist Technology — **GPLv3**.
- `fifo/` — synchronous FIFO by Dan Gisselquist — **public domain**.

All new RTL and Python in this repository (top-level, controller, crypto_engine,
shifter, testbenches, host scripts) is likewise released under **GPLv3** in
keeping with the third-party components it links against.

## Citation

```bibtex
@inproceedings{trochatos2026soteriaq,
  author    = {Trochatos, Theodoros and Xu, Chuanqi and Deshpande, Sanjay
               and Lu, Yao and Ding, Yongshan and Szefer, Jakub},
  title     = {SoteriaQ: Secure Quantum Computation via Gate-Level
               Obfuscation from Untrusted Clouds},
  booktitle = {2026 IEEE International Conference on Quantum Computing
               and Engineering (QCE)},
  year      = {2026}
}
```

Supported in part by NSF grant #2332406.
