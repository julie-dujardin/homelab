# auto-colony-replay

Replays of [auto-colony](https://github.com/julie-dujardin/auto-colony) runs on the web (`auto-colony-replay serve`).

| Host port | Container | What | Reached from |
|---|---|---|---|
| 8090 | 8080 | private viewer: game textures, Langfuse links | tunnel, behind Cloudflare Access |
| 8091 | 8081 | public viewer: footage only, no game files | tunnel, open |
| 8092 | 8082 | ingest: takes recordings in | LAN only |

The public viewer never gets the game's textures, only pictures of the map the server draws with them (footage): the RimWorld EULA allows sharing footage, not the game's files.

## Setup

1. Folders, owned by the container's user (docker would make them for root, and the server would stop on start saying it cannot write):

        sudo install -d -o 1000 -g 998 /var/lib/ilus/auto-colony-replay/data
        sudo install -d -o 1000 -g 998 /var/lib/ilus/auto-colony-replay/rimworld

2. Game files, from the desktop's Steam install (`~/.local/share/Steam/steamapps/common/RimWorld`, or with Flatpak `~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/RimWorld`). Only what the server reads: `Version.txt`, `Data/Core/Defs/`, and from `RimWorldLinux_Data/` (`RimWorldWin64_Data/` on Windows) `globalgamemanagers` and `resources.assets*`. Keep a single `*_Data` folder.

        cd ~/.local/share/Steam/steamapps/common/RimWorld
        rsync -aR --delete --chmod=Da+rx,Fa+r Version.txt Data/Core/Defs \
            RimWorldLinux_Data/globalgamemanagers RimWorldLinux_Data/resources.assets* \
            <nas>:/var/lib/ilus/auto-colony-replay/rimworld/

    `--delete` only clears defs the game no longer has. Without these files everything works, but both maps are plain colours and there is no footage.

3. `cp .env.example .env`, then Cloudflare, below, for `ACCESS_TEAM_DOMAIN` and `ACCESS_AUD` (the server does not start without them), and `INGEST_TOKEN` from `openssl rand -hex 32`.

4. The image is private on GHCR until made public. Either:
    - make it public (it has no game files): the package's page on GitHub > Package settings > Change package visibility > Public
    - or `docker login ghcr.io -u julie-dujardin` on the NAS with a classic token with `read:packages`, and mount that `~/.docker/config.json` in watchtower at `/config.json:ro` so it can pull too

5. `docker compose up -d`

## Cloudflare

Access first, for the private hostname only (menu names as of November 2026):

1. Zero Trust > Integrations > Identity providers: add One-time PIN if it's not there.
2. Zero Trust > Access controls > Applications > Create new application > Self-hosted and private: public hostname `colony-private.ilus.pw`, login method One-time PIN.
3. Access policy: action Allow, include "Emails ending in" `@<domain>`. Create.
4. Into `.env`: the application's Application Audience (AUD) Tag (Edit > Additional settings) as `ACCESS_AUD`, and the team domain from Zero Trust > Settings, `<team>.cloudflareaccess.com`, as `ACCESS_TEAM_DOMAIN`.

The server checks Access's token on every private request itself (403 otherwise), as 8090 is open on the LAN too.

Then the tunnel (dashboard-managed, `compose/cloudflared`): Networking > Tunnels > the tunnel > Routes > Add route > Published application, two of them, the service URL to the NAS's LAN IP like the other stacks:

| Hostname (example) | Service URL |
|---|---|
| `colony.ilus.pw` | `http://<NAS LAN IP>:8091` |
| `colony-private.ilus.pw` | `http://<NAS LAN IP>:8090` |

Never add 8092. Like every port here it is open on all the NAS's addresses, so it stays on the LAN only as long as neither the tunnel nor the router forwards it; it takes nothing without the token anyway.

The public hostname has no Access application. Worth a rate limiting rule on it: the zone's Security > Security rules > Create rule > Rate limiting rules, hostname equals `colony.ilus.pw`, e.g. 300 requests per 10 seconds per IP, block for 10 seconds, with "Also apply rate limiting to cached assets" off where offered. Footage pictures are cached by Cloudflare (immutable), so most requests never reach the NAS.

## Sending recordings

In auto-colony's `.env`:

    AUTO_COLONY_UPLOAD_URL=http://<NAS LAN IP>:8092
    AUTO_COLONY_UPLOAD_TOKEN=<INGEST_TOKEN>

Each run is then sent as it's played. Old recordings, from the auto-colony checkout (resumes, so it can be run again):

    uv run --env-file .env auto-colony-replay upload replays/*.jsonl

## Running it

- Update: watchtower moves it to `latest`, built from main once its checks pass. By hand: `docker compose pull && docker compose up -d`
- Game update: copy the files again, `docker compose restart`. Textures are cached per game version, the old `data/art-cache/<version>/` can be deleted.
- Logs: `docker logs -f auto-colony-replay`, one line per request (no tokens), also in Loki through promtail.
- Data, under `/var/lib/ilus/auto-colony-replay/data/`:
    - `replays/<session>.jsonl`: the recordings
    - `footage/<session>/`: `manifest.jsonl`, `img/*.webp`, `progress.json`
    - `art-cache/`: the game's textures as PNG, private: don't share
- Disk: footage is never pruned. Every chunk (16x16 cells) that changes in a frame is a 10-60 KB picture, so a recording's first frame is 3-15 MB on a 250x250 map (256 chunks), and it grows with every change after. Check with `du -sh data/footage/*`. To get space back, stop the stack and delete a `footage/<session>/`: it's drawn again from the recording on the next start.
- Memory: 3g is meant to leave room for Chromium with 3 recordings open; adjust after a look at `docker stats auto-colony-replay`.
