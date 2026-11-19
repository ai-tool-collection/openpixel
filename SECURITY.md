# Security policy

## Reporting a problem

Please report vulnerabilities **privately** through
[GitHub's private vulnerability reporting](https://github.com/sophne/openpixel/security/advisories/new), not in a
public issue. Include what you found, how to reproduce it, and which version you used. You'll get a reply within a
week, and a fix is released as soon as it's ready, with credit to you unless you prefer otherwise.

## Supported versions

Only the latest release gets security fixes. OpenPixel updates itself, so most people get them within a day.

## What OpenPixel trusts

- **Files**: `.openpixel`, `.vox` and images are treated as untrusted input and parsed with bounds checks.
- **Agents over stdio** (`OpenPixel --mcp`) run as you and can open and save files anywhere you can, like any local
  tool you give your agent.
- **Agents over HTTP** (`OpenPixel --mcp-http`) listen on 127.0.0.1 only, need a random secret in the URL, and can
  only open and save files inside `~/Documents/OpenPixel`. Anyone with the full URL can edit, so keep it private.
- **The app window** talks to agents through a socket in `~/Library/Application Support/OpenPixel` that only your
  user can open.
- **Updates** are downloaded over HTTPS from GitHub and installed only if their EdDSA signature matches the key built
  into the app. Releases are signed with a Developer ID and notarized by Apple.
