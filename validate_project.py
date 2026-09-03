from pathlib import Path
import plistlib

root = Path(__file__).parent
with (root / "HelloIPA/Info.plist").open("rb") as handle:
    plist = plistlib.load(handle)
for forbidden in ("M3SB_API_BASE_URL", "M3SB_HMAC_SECRET", "M3SB_PACKAGE_TOKEN"):
    assert forbidden not in plist, forbidden
source = (root / "HelloIPA/AppDelegate.swift").read_text()
assert 'static let accessKey = "M3SBxYAGAMI"' in source
for forbidden in ("URLSession", "api.m3sbapi.shop", "heartbeat", "CryptoKit"):
    assert forbidden not in source, forbidden
print("validation passed: plist is valid and activation is local-only")
