# Runs the PowerShell installer tests where PowerShell 7 is not installed
# locally. `just test-powershell` builds this image and mounts the repository.
# The tests are Python, so the image adds python3 to PowerShell.
FROM mcr.microsoft.com/powershell:7.5-ubuntu-24.04

RUN apt-get update \
    && apt-get install --yes --no-install-recommends python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /repo
