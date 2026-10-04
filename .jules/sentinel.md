## 2026-03-30 - Rejection of Constant-Time String Comparison for Local Sync
**Vulnerability:** Standard string comparison (`!=`) on `SyncService` authorization secret headers.
**Learning:** In this project's threat model, `SyncService` is purely a local Wi-Fi LAN sync between personal devices. Wi-Fi packet jitter (milliseconds) dwarfs nanosecond string comparison differences, making timing side-channel attacks unfeasible in practice.
**Prevention:** Do not add custom constant-time string comparison loops to local Wi-Fi sync components in this codebase when standard equality is sufficient for the local threat model.
