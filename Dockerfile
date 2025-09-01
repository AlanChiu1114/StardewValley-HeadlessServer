# Multi-stage build for Stardew Valley headless Linux server with SMAPI and mods

# Stage 1: Download Linux Stardew Valley via SteamCMD
FROM steamcmd/steamcmd:latest AS downloader

ARG STEAM_USERNAME
ARG STEAM_PASSWORD

ENV STEAMAPPID=413150 \
  STEAMAPPDIR=/game

RUN set -eux; \
  success=0; \
  for attempt in $(seq 1 10); do \
    echo "SteamCMD login/app_update attempt ${attempt}/10"; \
    if steamcmd +@sSteamCmdForcePlatformType linux +@sSteamCmdForcePlatformBitness 64 \
        +login "$STEAM_USERNAME" "$STEAM_PASSWORD" \
        +force_install_dir "$STEAMAPPDIR" \
        +app_update $STEAMAPPID validate \
        +quit; then \
      success=1; \
      break; \
    else \
      echo "SteamCMD failed (possibly waiting for Steam Guard mobile approval). Retrying in 30s..."; \
      sleep 30; \
    fi; \
  done; \
  if [ "$success" -ne 1 ]; then echo "SteamCMD failed after multiple attempts"; exit 5; fi; \
  # cleanup any steam data/certs/tokens
  rm -rf /root/.steam /root/Steam /steamcmd/steamapps/temp || true


# Stage 2: Prepare game with SMAPI + Mods
FROM debian:bookworm-slim AS prepare

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      unzip ca-certificates bash; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /

# Bring in the downloaded game files
COPY --from=downloader /game /game

# Copy inputs needed to install SMAPI
COPY ["mods/SMAPI 4.3.2 installer/internal/linux/install.dat", "/tmp/smapi-install.dat"]

# Copy helper scripts & configs
COPY scripts/install_smapi.sh /usr/local/bin/install_smapi.sh
COPY scripts/install_mods.sh /usr/local/bin/install_mods.sh
COPY configs /configs

RUN set -eux; \
  # normalize line endings to LF
  sed -i 's/\r$//' /usr/local/bin/install_smapi.sh /usr/local/bin/install_mods.sh; \
  chmod +x /usr/local/bin/install_smapi.sh /usr/local/bin/install_mods.sh; \
    /usr/local/bin/install_smapi.sh; \
    # install_mods.sh now only handles legacy mods if present (noop here)\
    /usr/local/bin/install_mods.sh || true; \
    # remove temp payloads
    rm -rf /tmp/*


# Stage 2.5: Build JunimoServer mod from source
FROM mcr.microsoft.com/dotnet/sdk:6.0-bookworm-slim AS modbuilder
WORKDIR /src
# Copy game files (with SMAPI) so ModBuildConfig can resolve references
COPY --from=prepare /game /game
# Copy JunimoServer source
COPY mods/server-master/mod/ /src/

RUN set -eux; \
    # build JunimoServer with GamePath pointing to /game\
    dotnet restore "/src/JunimoServer/JunimoServer.csproj"; \
  dotnet build -c Release \
      -p:GamePath=/game \
      -p:EnableModZip=false -p:EnableModDeploy=false \
      "/src/JunimoServer/JunimoServer.csproj"; \
    # collect mod output\
    mkdir -p /mods-out/JunimoServer; \
    cp -f /src/JunimoServer/manifest.json /mods-out/JunimoServer/; \
  cp -f /src/JunimoServer/bin/Release/net6.0/*.dll /mods-out/JunimoServer/ || true; \
  # Drop problematic framework DLLs that the game already provides
  rm -f /mods-out/JunimoServer/System.Threading.Channels.dll \
      /mods-out/JunimoServer/GalaxyCSharp.dll \
      /mods-out/JunimoServer/Steamworks.NET.dll || true; \
    # include common optional asset folders if present\
    for d in assets i18n config; do \
      if [ -d "/src/JunimoServer/$d" ]; then cp -a "/src/JunimoServer/$d" "/mods-out/JunimoServer/"; fi; \
    done


# Stage 3: Runtime image
FROM debian:bookworm-slim AS runtime

ENV LANG=C.UTF-8 \
  XDG_CONFIG_HOME=/data \
  DOTNET_SYSTEM_GLOBALization_Invariant=1 \
  LIBGL_ALWAYS_SOFTWARE=1 \
  SDL_AUDIODRIVER=dummy \
  SDL_VIDEODRIVER=x11 \
  XDG_RUNTIME_DIR=/tmp/xdg \
  # Force OpenAL Soft to use null (no-op) backend in headless
  ALSOFT_DRIVERS=null \
  # JunimoServer runtime optimizations (less rendering in headless)
  DISABLE_RENDERING=true

# Minimal runtime dependencies for Stardew (Linux) + SMAPI
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates curl bash \
  xvfb xauth \
      libgl1 libgl1-mesa-dri libglu1-mesa \
  libx11-6 libxrandr2 libxinerama1 libxcursor1 libxi6 libxext6 libxrender1 libxfixes3 libxdamage1 libxxf86vm1 libdrm2 libxcb1 \
      libasound2 libopenal1 libcurl4 libstdc++6 \
  libgdiplus \
  libsdl2-2.0-0 libsdl2-image-2.0-0 libsdl2-mixer-2.0-0 libsdl2-ttf-2.0-0 \
  procps iproute2 fonts-liberation libfreetype6 libfontconfig1 \
  mesa-utils xserver-xorg-core xserver-xorg-video-dummy; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /game

COPY --from=prepare /game /game
COPY --from=modbuilder /mods-out/JunimoServer /game/Mods/JunimoServer
RUN set -eux; \
  rm -rf /game/Mods/DedicatedServer /game/Mods/StardewUnattendedServer || true

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 24642/tcp 24642/udp

COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=10 \
  CMD /usr/local/bin/healthcheck.sh

VOLUME ["/data"]

ENTRYPOINT ["/entrypoint.sh"]
