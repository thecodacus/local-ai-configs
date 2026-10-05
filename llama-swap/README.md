# llama-swap config: Strata + llama.cpp + Qwen-Image behind one endpoint

My [llama-swap](https://github.com/mostlygeek/llama-swap) setup from the Codacus video on running Qwen 3.8 Flash with [Strata](https://github.com/Niko1221/Strata). One OpenAI-compatible endpoint on `:8080`; every model is picked by name, and llama-swap starts whichever backend serves it:

| Backend | What it serves | Models (by name) |
|---|---|---|
| **llama.cpp router** | everything in `models.ini` | `qwen36-35b-a3b-128k`, `qwen38-27b-gsq`, `ornith-35b-128k`, … |
| **Strata** | Qwen3.8-Flash-Next (GSQ-RCO IQ3_XXS), 128k context | `qwen38-flash` (2 GPUs), `qwen38-flash-1gpu` |
| **stable-diffusion.cpp** | Qwen-Image 2.1 for `/v1/images/*` | `qwen-image`, `qwen-image-edit` |

All of them sit in one **exclusive swap group**, so only one holds the GPUs at a time. Ask for the 35B and llama-swap brings up the router; ask for `qwen38-flash` and it stops the router and starts Strata.

## The box it was tuned on

- 2× RTX 3060 12 GB (GPU0 on PCIe x8, GPU1 on x4, both on CPU lanes)
- Ryzen 9 7900X, 64 GB DDR5
- Linux, Docker with the NVIDIA Container Toolkit

Measured on that machine:

- Strata, Qwen3.8-Flash on one GPU: **900+ t/s prefill**, ~40 t/s decode (`strata-1gpu`)
- Swap llama.cpp router → Strata (1 GPU): ~34 s; Strata → router: ~15 s
- Strata pins ~40 GB of RAM while it's up; `ttl: 600` shuts it down after 10 idle minutes and gives that RAM back

## Files

| File | What it is |
|---|---|
| `config.yaml` | the llama-swap config: the router, the two Strata entries, the image models, and the exclusive group |
| `models.ini` | the llama.cpp router presets (`llama-server --models-preset models.ini --models-max 1`) |
| `strata/strata.sh` | starts Strata on the port llama-swap hands it: `strata.sh PORT [GPU] [CONFIG]` |
| `strata/strata-iq3_xxs*.json` | my Strata engine configs (both GPUs; GPU0 + image encoder on GPU1) |
| `Dockerfile` | the llama-swap container: llama-swap + a docker CLI (to start the router as a sibling container) + Python for Strata |

## Setup

1. **Install Strata** with its own installer (`./setup.sh` on Linux, `START-HERE.bat` on Windows; see its README). It downloads the model, builds the engine and writes its own config. The JSON files here are mine for reference: the parts that matter are `--max-context 131072`, `--kv int8`, `--spec 4`, and `--vision` in the 1-GPU one.
2. **Build llama.cpp** (CUDA) and **stable-diffusion.cpp** if you want the image models.
3. **Edit the `macros:` block** at the top of `config.yaml`: your models folder, the llama.cpp and sd.cpp checkouts, and where `strata.sh` lives. Put `models.ini` in your models folder (the router container sees it as `/models/models.ini`) and point its `model = /models/...` lines at your GGUFs.
4. **Build and run llama-swap:**

   ```bash
   docker build -t llama-swap:local .
   docker run -d --name llama-swap --network host --gpus all \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -v "$PWD":/config \
     -v /opt/strata:/opt/strata -v /opt/models:/models \
     llama-swap:local
   ```

   The router and image models run as sibling containers through the docker socket; Strata runs inside the llama-swap container from its own venv, so mount the Strata folder and your models at the same paths its config uses.

5. Point any OpenAI-compatible client at `http://<host>:8080/v1` and pick a model by name. `GET /v1/models` lists every preset.

## Notes

- **Keep the aliases in sync.** Every `[section]` in `models.ini` must also be listed under the `llamacpp` entry's `aliases:` in `config.yaml`, or llama-swap won't route that name to the router.
- **Upstream llama.cpp:** I build from my own fork. Two preset keys may differ on upstream: `no-mmap` (upstream uses `load-mode`) and `spec-type = draft-mtp` (MTP drafting). Check `llama-server --help` on your build.
- **No progress while loading:** with `sendLoadingState: false`, clients see nothing during a swap (up to ~34 s). Turn it on if your client tolerates loading text in the response.
- **Windows / WSL:** Strata caps pinned memory at 8 GiB for multi-GPU runs under Windows' driver model (WSL2 too), and the NVIDIA driver under WSL pins only about 1 GB. Linux is the place to run this.
- **Qwen-Image weights** are under the qwen-research licence (non-commercial).

## Licence

MIT, see the repo's [`LICENSE`](../LICENSE). The models and engines referenced here have their own licences.
