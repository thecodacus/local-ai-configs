# Local AI configs

Configs from my local AI setups, shared from the [Codacus](https://www.youtube.com/@codacus) videos. Each folder is one setup with its own README: what it runs, the hardware it was tuned on, the numbers I measured, and how to adapt it to your machine.

| Folder | What it is |
|---|---|
| [`llama-swap/`](llama-swap/) | One OpenAI-compatible endpoint for every local model: llama-swap in front of the llama.cpp router (`models.ini` presets), [Strata](https://github.com/Niko1221/Strata) for Qwen3.8-Flash, and Qwen-Image on stable-diffusion.cpp. Tuned on 2× RTX 3060 12 GB + 64 GB RAM. |

Paths in these configs are placeholders (`/opt/...`, `/models`); change them to yours. Numbers are from my own machine, so treat them as a reference point, not a promise.

## Licence

MIT, see [`LICENSE`](LICENSE). The models and engines these configs run have their own licences.
